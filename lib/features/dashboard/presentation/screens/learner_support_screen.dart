import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/services/api_client.dart';

class LearnerSupportScreen extends StatefulWidget {
  const LearnerSupportScreen({super.key});

  @override
  State<LearnerSupportScreen> createState() => _LearnerSupportScreenState();
}

class _LearnerSupportScreenState extends State<LearnerSupportScreen> {
  static const _categories = <String>[
    'account_access',
    'profile_update',
    'learning_progress',
    'exam_access',
    'other',
  ];

  final _api = ApiClient();
  final _uuid = const Uuid();
  final _formKey = GlobalKey<FormState>();
  final _subject = TextEditingController();
  final _message = TextEditingController();
  String _submissionKey = const Uuid().v4();
  bool _submissionKeyHasBeenUsed = false;
  String _category = 'other';
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final requests = await _api.fetchSupportRequests();
      if (!mounted) return;
      setState(() => _requests = requests);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final strings = AppStrings.of(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
      _success = null;
      _submissionKeyHasBeenUsed = true;
    });
    try {
      await _api.submitSupportRequest(
        category: _category,
        subject: _subject.text,
        message: _message.text,
        idempotencyKey: _submissionKey,
      );
      if (!mounted) return;
      _subject.clear();
      _message.clear();
      setState(() {
        _success = strings.supportSentSuccess;
        _submissionKey = _uuid.v4();
        _submissionKeyHasBeenUsed = false;
      });
      await _loadRequests();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.learnerSupport)),
      body: RefreshIndicator(
        onRefresh: _loadRequests,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(strings.supportHelpTitle,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(strings.supportIntro,
                style: TextStyle(color: colors.onSurfaceVariant, height: 1.45)),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _category,
                          decoration: InputDecoration(
                              labelText: strings.supportRequestType),
                          items: _categories
                              .map((category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(strings.supportLabel(category))))
                              .toList(),
                          onChanged: _submitting
                              ? null
                              : (value) => setState(() {
                                    if (_submissionKeyHasBeenUsed) {
                                      _submissionKey = _uuid.v4();
                                      _submissionKeyHasBeenUsed = false;
                                    }
                                    _category = value ?? 'other';
                                  }),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _subject,
                          maxLength: 120,
                          enabled: !_submitting,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                              labelText: strings.supportSubject,
                              hintText: strings.supportSubjectHint),
                          validator: (value) => (value?.trim().length ?? 0) < 5
                              ? strings.supportSubjectValidation
                              : null,
                          onChanged: (_) {
                            if (_submissionKeyHasBeenUsed) {
                              setState(() {
                                _submissionKey = _uuid.v4();
                                _submissionKeyHasBeenUsed = false;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _message,
                          minLines: 4,
                          maxLines: 7,
                          maxLength: 2000,
                          enabled: !_submitting,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                              labelText: strings.supportDetails,
                              alignLabelWithHint: true,
                              hintText: strings.supportDetailsHint),
                          validator: (value) => (value?.trim().length ?? 0) < 10
                              ? strings.supportDetailsValidation
                              : null,
                          onChanged: (_) {
                            if (_submissionKeyHasBeenUsed) {
                              setState(() {
                                _submissionKey = _uuid.v4();
                                _submissionKeyHasBeenUsed = false;
                              });
                            }
                          },
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Semantics(
                              liveRegion: true,
                              child: Text(_error!,
                                  style: TextStyle(color: colors.error))),
                        ],
                        if (_success != null) ...[
                          const SizedBox(height: 8),
                          Text(_success!,
                              style: TextStyle(color: colors.primary)),
                        ],
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          onPressed: _submitting ? null : _submit,
                          icon: _submitting
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.send_rounded),
                          label: Text(_submitting
                              ? strings.supportSending
                              : strings.supportSendRequest),
                        ),
                      ]),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                  child: Text(strings.supportYourRequests,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800))),
              IconButton(
                  tooltip: strings.supportRefreshRequests,
                  onPressed: _loading ? null : _loadRequests,
                  icon: const Icon(Icons.refresh_rounded)),
            ]),
            const SizedBox(height: 8),
            if (_loading && _requests.isEmpty)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(28),
                      child: CircularProgressIndicator()))
            else if (_error != null && _requests.isEmpty)
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(strings.supportLoadError,
                          style: TextStyle(color: colors.onSurfaceVariant))))
            else if (_requests.isEmpty)
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(strings.supportEmpty,
                          style: TextStyle(color: colors.onSurfaceVariant))))
            else
              ..._requests.map((request) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                      child: Text('${request['subject'] ?? ''}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700))),
                                  const SizedBox(width: 8),
                                  Chip(
                                      label: Text(
                                          strings.supportLabel(
                                              '${request['status'] ?? 'open'}'),
                                          style: const TextStyle(fontSize: 11)),
                                      visualDensity: VisualDensity.compact),
                                ]),
                            Text(
                                strings.supportLabel(
                                    '${request['category'] ?? 'other'}'),
                                style: TextStyle(
                                    color: colors.primary, fontSize: 12)),
                            const SizedBox(height: 8),
                            Text('${request['message'] ?? ''}',
                                style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                    height: 1.4)),
                            if ((request['staffNote'] as String?)?.isNotEmpty ==
                                true) ...[
                              const Divider(height: 24),
                              Text(strings.supportUpdate,
                                  style: TextStyle(
                                      color: colors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12)),
                              const SizedBox(height: 4),
                              Text('${request['staffNote']}',
                                  style: TextStyle(
                                      color: colors.onSurfaceVariant,
                                      height: 1.4)),
                            ],
                          ]),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
