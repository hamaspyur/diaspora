class FixPhotoShareVisibilitiesForPodsWithoutTmpOldId < ActiveRecord::Migration
  def self.up
    raise "this migration is not yet compatible with postgres" if postgres?

    return  if Photo.first.respond_to?(:tmp_old_id)


    #migrate all the visibilities back(making the assumption that there are less photos than posts)
    execute %{
UPDATE `share_visibilities` SET `share_visibilities`.shareable_type = 'Post' where `share_visibilities`.shareable_id < (select count(*) from `photos`)
    }

    #delete all share visibilities not refrencing posts
    execute %{
DELETE `share_visibilities`.* FROM `share_visibilities` JOIN `posts` ON `share_visibilities`.shareable_id NOT IN ( SELECT id FROM posts ) ;
    }

    #generate data needed to create visibilities for photos
    #
    #insert photo visibilities
    execute %{
CREATE TEMPORARY TABLE vis_for_photos
SELECT `photos`.id as photo_id, 'Photo' as type, `share_visibilities`.contact_id as contact_id
FROM photos
JOIN posts
JOIN share_visibilities
ON `posts`.type = 'StatusMessage' AND `posts`.guid = `photos`.status_message_guid
 AND `share_visibilities`.shareable_id = `posts`.id;

INSERT INTO share_visibilities 
SET `share_visibilities `.shareable_id = `vis_for_photos`.photo_id,
`share_visibilities `.shareable_type = `vis_for_photos`.type,
`share_visibilities `.contact_id = `vis_for_photos`.contact_id;
    }

  end

  def self.down
  end
end
