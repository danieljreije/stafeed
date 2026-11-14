/**
 * Categories Stafeed never shows (spec user story 80). Sources must use these
 * IDs for such Products; `guardSource` drops them at the adapter boundary.
 * The migrations seed the same list into `categories` with `prohibited`.
 */
export const PROHIBITED_CATEGORIES: ReadonlySet<string> = new Set([
  'adult',
  'weapons',
  'tobacco',
  'drugs',
  'counterfeits',
  'gambling',
  'dangerous-goods',
]);

export function isProhibitedCategory(categoryId: string): boolean {
  return PROHIBITED_CATEGORIES.has(categoryId);
}
