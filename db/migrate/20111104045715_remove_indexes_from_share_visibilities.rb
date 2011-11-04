class RemoveIndexesFromShareVisibilities < ActiveRecord::Migration
  def self.up
    execute <<SQL
      ALTER TABLE share_visibilities
        DROP INDEX index_post_visibilities_on_post_id,
        DROP INDEX shareable_and_hidden_and_contact_id
SQL
  end

  def self.down
    add_index "share_visibilities", ["shareable_id"]
    add_index "share_visibilities", ["shareable_id", "shareable_type", "hidden", "contact_id"]
  end
end
