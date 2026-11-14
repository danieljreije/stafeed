// Opaque feed cursors. Callers just hand them back; only this module reads
// them. A cursor only continues the feed it came from: the same Destination
// Country, category and search.

const prefix = 'c1.';

export class InvalidCursorError extends Error {
  constructor() {
    super('This cursor was not issued for this feed.');
    this.name = 'InvalidCursorError';
  }
}

export function writeCursor(offset: number, fingerprint: string): string {
  const payload = JSON.stringify({ o: offset, f: fingerprint });
  return prefix + toBase64Url(new TextEncoder().encode(payload));
}

/** The offset [cursor] points at. Throws [InvalidCursorError] otherwise. */
export function readCursor(cursor: string, fingerprint: string): number {
  try {
    if (!cursor.startsWith(prefix)) throw new InvalidCursorError();
    const json = new TextDecoder('utf-8', { fatal: true }).decode(
      fromBase64Url(cursor.slice(prefix.length)),
    );
    const payload: unknown = JSON.parse(json);
    if (
      typeof payload === 'object' &&
      payload !== null &&
      'o' in payload &&
      'f' in payload &&
      Number.isSafeInteger(payload.o) &&
      (payload.o as number) > 0 &&
      payload.f === fingerprint
    ) {
      return payload.o as number;
    }
  } catch {
    // Falls through: anything unreadable is simply not our cursor.
  }
  throw new InvalidCursorError();
}

function toBase64Url(bytes: Uint8Array): string {
  let binary = '';
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replaceAll('+', '-').replaceAll('/', '_').replace(/=+$/, '');
}

function fromBase64Url(text: string): Uint8Array {
  if (!/^[A-Za-z0-9_-]*$/.test(text)) throw new InvalidCursorError();
  const base64 = text.replaceAll('-', '+').replaceAll('_', '/');
  const binary = atob(base64.padEnd(Math.ceil(base64.length / 4) * 4, '='));
  return Uint8Array.from(binary, (char) => char.charCodeAt(0));
}
