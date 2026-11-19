import fs from 'node:fs';
import path from 'node:path';
import { defineConfig, Plugin, transformWithEsbuild } from 'vite';
import react from '@vitejs/plugin-react';

const resolvePath = (relPath: string) =>
  decodeURIComponent(new URL(relPath, import.meta.url).pathname);

const DATA_DIR = resolvePath('.data');
const TELEMETRY_LOCKS_FILE = path.join(DATA_DIR, 'telemetry_locks.jsonl');
const EXAM_SUBMISSIONS_FILE = path.join(DATA_DIR, 'exam_submissions.jsonl');
const CONVERSATIONS_FILE = path.join(DATA_DIR, 'conversations.jsonl');
const TRAINING_CORPUS_FILE = path.join(DATA_DIR, 'aether_training_corpus.jsonl');
const APP_USAGE_FILE = path.join(DATA_DIR, 'app_usage.json');

function ensureDataDir(): void {
  try {
    if (!fs.existsSync(DATA_DIR)) {
      fs.mkdirSync(DATA_DIR, { recursive: true });
    }
  } catch {
    // ignore fs errors on read-only mounts
  }
}

function appendJsonl(filePath: string, record: unknown): void {
  try {
    ensureDataDir();
    fs.appendFileSync(filePath, `${JSON.stringify(record)}\n`, 'utf8');
  } catch {
    // ignore fs errors
  }
}

function readJsonl<T = Record<string, unknown>>(filePath: string): T[] {
  try {
    if (!fs.existsSync(filePath)) return [];
    const lines = fs
      .readFileSync(filePath, 'utf8')
      .split('\n')
      .map((l) => l.trim())
      .filter(Boolean);
    return lines
      .map((line) => {
        try {
          return JSON.parse(line) as T;
        } catch {
          return null;
        }
      })
      .filter((x): x is T => Boolean(x))
      .reverse();
  } catch {
    return [];
  }
}

function readJsonFile<T>(filePath: string, fallback: T): T {
  try {
    if (!fs.existsSync(filePath)) return fallback;
    return JSON.parse(fs.readFileSync(filePath, 'utf8')) as T;
  } catch {
    return fallback;
  }
}

function writeJsonFile(filePath: string, value: unknown): void {
  try {
    ensureDataDir();
    fs.writeFileSync(filePath, JSON.stringify(value, null, 2), 'utf8');
  } catch {
    // ignore fs errors
  }
}

const extensions = [
  '.web.tsx',
  '.web.ts',
  '.web.jsx',
  '.web.js',
  '.tsx',
  '.ts',
  '.jsx',
  '.js',
];

const reanimatedJsxPlugin = {
  name: 'reanimated-jsx-in-js',
  enforce: 'pre' as const,
  async transform(code: string, id: string) {
    const cleanId = id.split('?')[0];
    if (cleanId.includes('react-native-reanimated') && cleanId.endsWith('.js')) {
      return transformWithEsbuild(code, cleanId, {
        loader: 'jsx',
        jsx: 'automatic',
      });
    }
    return null;
  },
};

interface ServerConversationTurn {
  threadId: string;
  userId: string;
  mode: string;
  userMessage: string;
  assistantContent: string;
  modelSource: string;
  timestamp: string;
}

const ROOT_DIR = resolvePath('..');
const DEFAULT_ANDROID_OAUTH_CLIENT_ID =
  '560610133772-03ij6u6cqo2pk1t2tbjvmpqrl79md609.apps.googleusercontent.com';

function readEnvFileVars(): Record<string, string> {
  const vars: Record<string, string> = {};
  for (const filename of ['.env', '.env.local']) {
    const filePath = path.join(ROOT_DIR, filename);
    try {
      if (!fs.existsSync(filePath)) continue;
      const lines = fs.readFileSync(filePath, 'utf8').split('\n');
      for (const rawLine of lines) {
        const line = rawLine.trim();
        if (!line || line.startsWith('#')) continue;
        const eqIdx = line.indexOf('=');
        if (eqIdx <= 0) continue;
        const key = line.slice(0, eqIdx).trim();
        let val = line.slice(eqIdx + 1).trim();
        if (
          (val.startsWith('"') && val.endsWith('"')) ||
          (val.startsWith("'") && val.endsWith("'"))
        ) {
          val = val.slice(1, -1);
        }
        vars[key] = val;
      }
    } catch {
      // ignore unreadable .env files
    }
  }
  return vars;
}

function isPlaceholderEnvValue(val: string): boolean {
  const lower = val.trim().toLowerCase();
  if (!lower) return true;
  return (
    lower.includes('your-project') ||
    lower.includes('your-supabase') ||
    lower.includes('your-google') ||
    lower.includes('placeholder') ||
    lower.startsWith('<')
  );
}

function getRuntimeSupabaseConfig(req: { headers?: Record<string, string | string[] | undefined> }) {
  const fileVars = readEnvFileVars();
  const pick = (...keys: string[]) => {
    for (const k of keys) {
      const envVal = process.env[k];
      if (envVal && !isPlaceholderEnvValue(envVal)) return envVal.trim();
      const fileVal = fileVars[k];
      if (fileVal && !isPlaceholderEnvValue(fileVal)) return fileVal.trim();
    }
    return '';
  };

  const supabaseUrl = pick('SUPABASE_URL', 'VITE_SUPABASE_URL');
  const supabaseAnonKey = pick('SUPABASE_ANON_KEY', 'VITE_SUPABASE_ANON_KEY');
  const nativeRedirectUri =
    pick('AUTH_REDIRECT_URI', 'VITE_AUTH_REDIRECT_URI') ||
    'com.rxxxeron.prep404://login-callback';
  const googleAndroidClientId =
    pick(
      'GOOGLE_ANDROID_CLIENT_ID',
      'VITE_GOOGLE_ANDROID_CLIENT_ID',
      'GOOGLE_CLIENT_ID'
    ) || DEFAULT_ANDROID_OAUTH_CLIENT_ID;
  const googleWebClientId = pick('GOOGLE_WEB_CLIENT_ID', 'VITE_GOOGLE_WEB_CLIENT_ID');

  const appUrl = pick('APP_URL');
  const hostHeader = String(req.headers?.host || '').trim();
  const protoHeader = String(req.headers?.['x-forwarded-proto'] || 'https').trim();
  const origin =
    appUrl || (hostHeader ? `${protoHeader}://${hostHeader}` : 'http://localhost:3000');

  return {
    configured: Boolean(supabaseUrl && supabaseAnonKey),
    supabaseUrl,
    supabaseAnonKey,
    nativeRedirectUri,
    googleAndroidClientId,
    googleWebClientId,
    webCallbackUrl: `${origin.replace(/\/$/, '')}/auth/callback`,
  };
}

const OAUTH_CALLBACK_HTML = `<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Prep404 · Completing Google Sign-In</title>
    <style>
      body {
        margin: 0;
        min-height: 100vh;
        display: flex;
        align-items: center;
        justify-content: center;
        background: #FAF9F6;
        color: #14191F;
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      }
      .card {
        padding: 24px 28px;
        border-radius: 14px;
        border: 1px solid #E5E1D8;
        background: #FFFFFF;
        max-width: 360px;
        text-align: center;
      }
      h1 { font-size: 16px; margin: 0 0 8px; }
      p { font-size: 13px; color: #52606D; margin: 0; line-height: 1.5; }
    </style>
  </head>
  <body>
    <div class="card">
      <h1>Signing you in to Prep404…</h1>
      <p id="status">Completing Google OAuth handoff. This window will close automatically.</p>
    </div>
    <script>
      (function () {
        function parseParams(raw) {
          var cleaned = (raw || '').replace(/^[?#]/, '');
          var out = {};
          if (!cleaned) return out;
          cleaned.split('&').forEach(function (part) {
            if (!part) return;
            var idx = part.indexOf('=');
            var k = idx >= 0 ? part.slice(0, idx) : part;
            var v = idx >= 0 ? part.slice(idx + 1) : '';
            try {
              out[decodeURIComponent(k.replace(/\\+/g, ' '))] = decodeURIComponent(v.replace(/\\+/g, ' '));
            } catch (e) {
              out[k] = v;
            }
          });
          return out;
        }
        var q = parseParams(window.location.search);
        var h = parseParams(window.location.hash);
        var payload = {
          type: 'PREP404_SUPABASE_OAUTH_CALLBACK',
          code: q.code || h.code || null,
          accessToken: h.access_token || q.access_token || null,
          refreshToken: h.refresh_token || q.refresh_token || null,
          error: q.error || h.error || null,
          errorDescription: q.error_description || h.error_description || null
        };
        if (window.opener && !window.opener.closed) {
          try {
            window.opener.postMessage(payload, window.location.origin);
          } catch (e) {
            window.opener.postMessage(payload, '*');
          }
          setTimeout(function () { window.close(); }, 150);
        } else {
          var next = '/' + window.location.search + window.location.hash;
          window.location.replace(next);
        }
      })();
    </script>
  </body>
</html>`;

const attachGatewayMiddleware = (middlewares: {
  use: (fn: (req: any, res: any, next: () => void) => void) => void;
}) => {
  middlewares.use(async (req, res, next) => {
    const url = req.url || '';
    const pathname = url.split('?')[0];

    if (pathname === '/auth/callback' || pathname === '/auth/callback/') {
      res.statusCode = 200;
      res.setHeader('Content-Type', 'text/html; charset=utf-8');
      res.end(OAUTH_CALLBACK_HTML);
      return;
    }

    if (!url.startsWith('/api/v1')) {
      next();
      return;
    }

    const readBody = (): Promise<Record<string, unknown>> =>
      new Promise((resolve) => {
        let raw = '';
        req.on('data', (chunk: unknown) => {
          raw += String(chunk);
        });
        req.on('end', () => {
          try {
            resolve(raw ? (JSON.parse(raw) as Record<string, unknown>) : {});
          } catch {
            resolve({});
          }
        });
      });

    res.setHeader('Content-Type', 'application/json');

    if (url.startsWith('/api/v1/auth/supabase-config') && req.method === 'GET') {
      const cfg = getRuntimeSupabaseConfig(req);
      res.statusCode = 200;
      res.end(JSON.stringify(cfg));
      return;
    }

    if (url.startsWith('/api/v1/health') && req.method === 'GET') {
      const locks = readJsonl(TELEMETRY_LOCKS_FILE);
      const turns = readJsonl(CONVERSATIONS_FILE);
      const training = readJsonl(TRAINING_CORPUS_FILE);
      res.statusCode = 200;
      res.end(
        JSON.stringify({
          ok: true,
          service: 'prep404_server_gateway',
          version: '2.0.0-real-pipeline',
          universities: ['NSU', 'BRACU', 'EWU', 'UIU', 'AIUB', 'AUST', 'UAP'],
          telemetryLocksIngested: locks.length,
          ledgerEntries: turns.length,
          trainingCorpusRows: training.length,
          timestamp: new Date().toISOString(),
        })
      );
      return;
    }

    if (url.startsWith('/api/v1/pipeline/state') && req.method === 'GET') {
      const telemetryLocks = readJsonl(TELEMETRY_LOCKS_FILE);
      const examSubmissions = readJsonl(EXAM_SUBMISSIONS_FILE);
      const conversations = readJsonl<ServerConversationTurn>(CONVERSATIONS_FILE);
      const trainingRows = readJsonl(TRAINING_CORPUS_FILE);
      const appUsage = readJsonFile(APP_USAGE_FILE, {
        activeFocusSeconds: 0,
        appSwitchCount: 0,
        sessionsStarted: 0,
        sessionsCompleted: 0,
        lastUpdatedAt: new Date().toISOString(),
      });
      res.statusCode = 200;
      res.end(
        JSON.stringify({
          ok: true,
          telemetryLocks,
          examSubmissions,
          conversations,
          trainingCorpusCount: trainingRows.length,
          appUsage,
        })
      );
      return;
    }

    if (url.startsWith('/api/v1/pipeline/reset') && req.method === 'POST') {
      try {
        [
          TELEMETRY_LOCKS_FILE,
          EXAM_SUBMISSIONS_FILE,
          CONVERSATIONS_FILE,
          TRAINING_CORPUS_FILE,
          APP_USAGE_FILE,
        ].forEach((file) => {
          if (fs.existsSync(file)) fs.unlinkSync(file);
        });
      } catch {
        // ignore
      }
      res.statusCode = 200;
      res.end(JSON.stringify({ ok: true, reset: true }));
      return;
    }

    if (url.startsWith('/api/v1/telemetry/answer-lock') && req.method === 'POST') {
      const body = await readBody();
      const touchPattern =
        (body.touchPattern as Record<string, unknown> | undefined) || {};
      const record = {
        ...body,
        schemaVersion: String(body.schemaVersion || 'aether-telemetry-v2'),
        serverIngestedAt: new Date().toISOString(),
      };
      appendJsonl(TELEMETRY_LOCKS_FILE, record);

      // Append a structured behavioral training example for aether-ai-7b-prep404 fine-tuning
      appendJsonl(TRAINING_CORPUS_FILE, {
        type: 'behavioral_answer_lock',
        model: 'aether-ai-7b-prep404',
        schemaVersion: record.schemaVersion,
        candidateId: String(body.candidateId || 'candidate'),
        platform: String(body.platform || 'react-native'),
        messages: [
          {
            role: 'system',
            content:
              'You are AETHER AI, the personalized private university admission & finger-telemetry evaluation engine for Prep404.',
          },
          {
            role: 'user',
            content: `Question Lock Telemetry: question=${String(body.questionId || '')}, subject=${String(body.subjectName || '')}, topic=${String(body.topicId || '')}, readTimeMs=${Number(body.readTimeMs || 0)}, thinkTimeMs=${Number(body.thinkTimeMs || 0)}, totalTimeMs=${Number(body.totalTimeMs || 0)}, touchCount=${Number(body.touchInteractionCount || 1)}, scrollCount=${Number(touchPattern.scrollCount || 0)}, hesitationGapMs=${Number(touchPattern.hesitationGapMs || 0)}, cadence=${String(touchPattern.touchCadenceLabel || 'steady_deliberate')}, lockedOption=${String(body.lockedOptionId || '')}, isCorrect=${Boolean(body.isCorrect)}, classification=${String(body.classification || 'deliberate')}`,
          },
          {
            role: 'assistant',
            content: `Evaluated permanent answer lock on ${String(body.questionId || '')} (${String(body.subjectName || '')}): ${Boolean(body.isCorrect) ? 'Correct' : 'Incorrect'} commit in ${Number(body.totalTimeMs || 0)}ms (Read ${Number(body.readTimeMs || 0)}ms -> Think ${Number(body.thinkTimeMs || 0)}ms · ${String(touchPattern.touchCadenceLabel || 'steady_deliberate')}) classified as ${String(body.classification || 'deliberate')}.`,
          },
        ],
        touchTrace: Array.isArray(touchPattern.touchTrace)
          ? touchPattern.touchTrace
          : [],
        recordedAt: new Date().toISOString(),
      });

      res.statusCode = 200;
      res.end(
        JSON.stringify({
          ok: true,
          recorded: true,
          schemaVersion: record.schemaVersion,
          eventId: String(body.eventId || ''),
          questionId: String(body.questionId || ''),
          classification: String(body.classification || 'deliberate'),
          touchCadence: String(touchPattern.touchCadenceLabel || 'steady_deliberate'),
        })
      );
      return;
    }

    if (url.startsWith('/api/v1/telemetry/app-usage') && req.method === 'POST') {
      const body = await readBody();
      writeJsonFile(APP_USAGE_FILE, {
        activeFocusSeconds: Number(body.activeFocusSeconds || 0),
        appSwitchCount: Number(body.appSwitchCount || 0),
        sessionsStarted: Number(body.sessionsStarted || 0),
        sessionsCompleted: Number(body.sessionsCompleted || 0),
        lastUpdatedAt: new Date().toISOString(),
      });
      res.statusCode = 200;
      res.end(JSON.stringify({ ok: true, saved: true }));
      return;
    }

    if (url.startsWith('/api/v1/exams/submit') && req.method === 'POST') {
      const body = await readBody();
      appendJsonl(EXAM_SUBMISSIONS_FILE, {
        ...body,
        serverIngestedAt: new Date().toISOString(),
      });
      res.statusCode = 200;
      res.end(JSON.stringify({ ok: true, saved: true }));
      return;
    }

    if (url.startsWith('/api/v1/training/export.jsonl') && req.method === 'GET') {
      const rows = readJsonl(TRAINING_CORPUS_FILE);
      res.setHeader('Content-Type', 'application/x-ndjson');
      res.statusCode = 200;
      res.end(rows.map((r) => JSON.stringify(r)).join('\n'));
      return;
    }

    if (url.startsWith('/api/v1/ai/tunnel-handshake') && req.method === 'POST') {
      const body = await readBody();
      const tunnelUrl = String(body.cloudflareTunnelUrl || '').trim();
      const modelName = String(body.localModelName || 'aether-ai-7b-prep404');
      const start = Date.now();

      let remoteReachable = false;
      if (
        tunnelUrl.startsWith('https://') &&
        !tunnelUrl.includes('a4000-cluster.fourzerofour.tech')
      ) {
        try {
          const controller = new AbortController();
          const timer = setTimeout(() => controller.abort(), 1800);
          const ping = await fetch(`${tunnelUrl.replace(/\/$/, '')}/v1/models`, {
            method: 'GET',
            signal: controller.signal,
          });
          clearTimeout(timer);
          remoteReachable = ping.ok;
        } catch {
          remoteReachable = false;
        }
      }

      const latencyMs = Math.max(4, Date.now() - start);
      const trainingCount = readJsonl(TRAINING_CORPUS_FILE).length;
      res.statusCode = 200;
      res.end(
        JSON.stringify({
          ok: true,
          status: remoteReachable ? 'connected' : 'local_gateway_ready',
          latencyMs,
          modelName,
          cloudflareTunnelUrl: tunnelUrl,
          trainingCorpusCount: trainingCount,
          message: remoteReachable
            ? `Connected to live Cloudflare Tunnel (${modelName}) in ${latencyMs}ms.`
            : `AETHER AI prep404_server pipeline active (${latencyMs}ms · ${trainingCount} real training records persisted).`,
        })
      );
      return;
    }

    if (url.startsWith('/api/v1/ai/chat') && req.method === 'POST') {
      const body = await readBody();
      const tunnelUrl = String(body.cloudflareTunnelUrl || '').trim();
      const modelName = String(body.localModelName || 'aether-ai-7b-prep404');
      const systemPrompt = String(body.systemPrompt || '');
      const userMessage = String(body.userMessage || '');
      const threadId = String(body.threadId || `thr_${Date.now()}`);
      const userId = String(body.userId || 'candidate_01');
      const mode = String(body.mode || 'aether_solver');

      let remoteContent = '';
      if (
        tunnelUrl.startsWith('https://') &&
        !tunnelUrl.includes('a4000-cluster.fourzerofour.tech')
      ) {
        try {
          const controller = new AbortController();
          const timer = setTimeout(() => controller.abort(), 3200);
          const upstream = await fetch(
            `${tunnelUrl.replace(/\/$/, '')}/v1/chat/completions`,
            {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                model: modelName,
                messages: [
                  { role: 'system', content: systemPrompt },
                  { role: 'user', content: userMessage },
                ],
              }),
              signal: controller.signal,
            }
          );
          clearTimeout(timer);
          if (upstream.ok) {
            const data = (await upstream.json()) as {
              choices?: { message?: { content?: string } }[];
            };
            remoteContent = data?.choices?.[0]?.message?.content || '';
          }
        } catch {
          remoteContent = '';
        }
      }

      const turnRecord: ServerConversationTurn = {
        threadId,
        userId,
        mode,
        userMessage,
        assistantContent:
          remoteContent || '[Synthesized by Prep404 AETHER AI Engine]',
        modelSource: remoteContent
          ? 'cloudflare_local_gpu'
          : 'prep404_server_gateway',
        timestamp: new Date().toISOString(),
      };
      appendJsonl(CONVERSATIONS_FILE, turnRecord);
      appendJsonl(TRAINING_CORPUS_FILE, {
        type: 'aether_conversation_turn',
        model: modelName,
        mode,
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userMessage },
          { role: 'assistant', content: turnRecord.assistantContent },
        ],
        recordedAt: turnRecord.timestamp,
      });

      if (remoteContent) {
        res.statusCode = 200;
        res.end(
          JSON.stringify({
            ok: true,
            content: remoteContent,
            socraticStep: 'synthesis',
            aetherStage: 'synthesis',
            modelSource: 'cloudflare_local_gpu',
          })
        );
        return;
      }

      res.statusCode = 200;
      res.end(
        JSON.stringify({
          ok: true,
          content: '',
          modelSource: 'prep404_server_gateway',
          ledgerSaved: true,
        })
      );
      return;
    }

    if (url.startsWith('/api/v1/ai/conversations') && req.method === 'GET') {
      const entries = readJsonl<ServerConversationTurn>(CONVERSATIONS_FILE);
      res.statusCode = 200;
      res.end(
        JSON.stringify({
          ok: true,
          count: entries.length,
          entries: entries.slice(0, 100),
        })
      );
      return;
    }

    if (url.startsWith('/api/v1/ai/response-reports') && req.method === 'POST') {
      const body = await readBody();
      res.statusCode = 201;
      res.end(
        JSON.stringify({
          success: true,
          id: `rep_${Date.now()}`,
          category: String(body.category || 'other'),
          questionId: String(body.questionId || ''),
        })
      );
      return;
    }

    if (url.startsWith('/api/v1/public/exams')) {
      res.statusCode = 200;
      res.end(
        JSON.stringify({
          ok: true,
          delivery: 'Prep404 Edge Delivery',
          universities: ['NSU', 'BRACU', 'EWU', 'UIU', 'AIUB', 'AUST', 'UAP'],
          timestamp: new Date().toISOString(),
        })
      );
      return;
    }

    res.statusCode = 200;
    res.end(JSON.stringify({ ok: true, route: url }));
  });
};

const prep404ServerGatewayPlugin: Plugin = {
  name: 'prep404-server-gateway-v1',
  configureServer(server) {
    attachGatewayMiddleware(server.middlewares);
  },
  configurePreviewServer(server) {
    attachGatewayMiddleware(server.middlewares);
  },
};

export default defineConfig({
  root: resolvePath('.'),
  publicDir: resolvePath('../public'),
  plugins: [reanimatedJsxPlugin, prep404ServerGatewayPlugin, react()],
  define: {
    __DEV__: JSON.stringify(process.env.NODE_ENV !== 'production'),
    global: 'window',
    'process.env': JSON.stringify({}),
  },
  resolve: {
    alias: [
      {
        find: '@react-native/assets-registry/registry',
        replacement: resolvePath(
          'node_modules/react-native-web/dist/cjs/modules/AssetRegistry/index.js'
        ),
      },
      {
        find: 'react-native/Libraries/Image/AssetRegistry',
        replacement: resolvePath(
          'node_modules/react-native-web/dist/cjs/modules/AssetRegistry/index.js'
        ),
      },
      {
        find: /^react-native-svg$/,
        replacement: resolvePath(
          'node_modules/react-native-svg/lib/module/ReactNativeSVG.web.js'
        ),
      },
      {
        find: /^react-native$/,
        replacement: resolvePath('node_modules/react-native-web/dist/cjs/index.js'),
      },
      {
        find: /^react-native-web$/,
        replacement: resolvePath('node_modules/react-native-web/dist/cjs/index.js'),
      },
      {
        find: /^react-native-web\/(?!dist\/)(.+)$/,
        replacement: resolvePath('node_modules/react-native-web/dist/cjs/$1'),
      },
    ],
    extensions,
  },
  optimizeDeps: {
    entries: ['index.html', 'index.web.ts'],
    include: [
      'react',
      'react-dom',
      'react/jsx-runtime',
      'react/jsx-dev-runtime',
      'react-native-web/dist/cjs/index.js',
      'react-native-web/dist/cjs/modules/AssetRegistry/index.js',
      'react-native-safe-area-context',
      '@react-native-async-storage/async-storage',
      '@supabase/supabase-js',
      'react-native-svg',
      'react-native-reanimated',
      'react-native-is-edge-to-edge',
      'invariant',
      'convert-source-map',
    ],
    exclude: [],
    esbuildOptions: {
      resolveExtensions: extensions,
      loader: {
        '.js': 'jsx',
      },
    },
  },
  build: {
    rollupOptions: {
      input: resolvePath('index.html'),
    },
  },
  server: {
    host: '0.0.0.0',
    port: 3000,
    strictPort: true,
    allowedHosts: true,
    cors: true,
    hmr: false,
  },
  preview: {
    host: '0.0.0.0',
    port: 3000,
    strictPort: true,
    allowedHosts: true,
    cors: true,
  },
});
