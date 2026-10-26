enum BufferProfile {
  fastZapping,
  balanced,
  highResilience,
}

extension BufferProfileExtension on BufferProfile {
  String get label {
    switch (this) {
      case BufferProfile.fastZapping:
        return 'Zapping Ultrarrápido (Baja latencia)';
      case BufferProfile.balanced:
        return 'Equilibrado (Estándar)';
      case BufferProfile.highResilience:
        return 'Alta Resiliencia (Conexión lenta / 4K)';
    }
  }

  String get labelEn {
    switch (this) {
      case BufferProfile.fastZapping:
        return 'Fast Zapping (Low Latency)';
      case BufferProfile.balanced:
        return 'Balanced (Default)';
      case BufferProfile.highResilience:
        return 'High Resilience (Slow / 4K)';
    }
  }

  int get maxBytes {
    switch (this) {
      case BufferProfile.fastZapping:
        return 32 * 1024 * 1024; // 32 MB
      case BufferProfile.balanced:
        return 64 * 1024 * 1024; // 64 MB
      case BufferProfile.highResilience:
        return 256 * 1024 * 1024; // 256 MB
    }
  }

  int get readaheadSeconds {
    switch (this) {
      case BufferProfile.fastZapping:
        return 5;
      case BufferProfile.balanced:
        return 15;
      case BufferProfile.highResilience:
        return 45;
    }
  }

  bool get cachePause {
    switch (this) {
      case BufferProfile.fastZapping:
        return false;
      case BufferProfile.balanced:
      case BufferProfile.highResilience:
        return true;
    }
  }
}
