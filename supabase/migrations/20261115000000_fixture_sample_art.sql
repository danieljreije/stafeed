-- Fixture pictures are now drawn by the app from `sample-art:` links instead
-- of being downloaded from picsum.photos. Allow those links, but only for
-- media whose source is the Fixtures: real sources must still send real
-- http(s) links.
alter table media_assets drop constraint media_assets_url_check;

alter table media_assets add constraint media_assets_url_check check (
  url ~ '^https?://'
  or (source = 'fixtures' and url ~ '^sample-art:[a-z0-9-]+/[A-Za-z0-9-]+$')
);
