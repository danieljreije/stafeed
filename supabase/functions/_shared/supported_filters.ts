import type { Category, SupportedFilters } from './domain.ts';
import type { GuardedSource } from './source_guard.ts';

/** Every allowed category any source supports, once each, in source order. */
export async function supportedFilters(
  sources: readonly GuardedSource[],
): Promise<SupportedFilters> {
  const categories: Category[] = [];
  for (const source of sources) {
    for (const category of (await source.supportedFilters()).categories) {
      if (!categories.some((c) => c.id === category.id)) categories.push(category);
    }
  }
  return { categories };
}
