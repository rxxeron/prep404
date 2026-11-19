import { useEffect, useState } from 'react';
import { Platform } from 'react-native';

export function useNetworkStatus(): boolean {
  const [isOnline, setIsOnline] = useState<boolean>(() => {
    if (Platform.OS === 'web' && typeof navigator !== 'undefined' && 'onLine' in navigator) {
      return Boolean(navigator.onLine);
    }
    return true;
  });

  useEffect(() => {
    if (Platform.OS !== 'web' || typeof window === 'undefined') return;
    const sync = () => {
      if (typeof navigator !== 'undefined' && 'onLine' in navigator) {
        setIsOnline(Boolean(navigator.onLine));
      }
    };
    window.addEventListener('online', sync);
    window.addEventListener('offline', sync);
    sync();
    return () => {
      window.removeEventListener('online', sync);
      window.removeEventListener('offline', sync);
    };
  }, []);

  return isOnline;
}
