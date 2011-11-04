class RemovePublicShareVisibilities < ActiveRecord::Migration
  def self.up
    execute <<SQL
      DELETE share_visibilities FROM share_visibilities
        INNER JOIN posts ON (share_visibilities.shareable_id = posts.id AND share_visibilities.shareable_type='Post')
          WHERE posts.public IS true
SQL

    execute <<SQL
      DELETE share_visibilities FROM share_visibilities
        INNER JOIN photos ON (share_visibilities.shareable_id = photos.id AND share_visibilities.shareable_type='Photo')
          WHERE photos.public IS true
SQL
  end

  def self.down
  end
end
