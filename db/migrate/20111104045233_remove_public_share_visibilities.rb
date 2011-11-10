class RemovePublicShareVisibilities < ActiveRecord::Migration
  def self.up
    # Prepare users table
    add_column :users, :hidden_shareables, :string, :default => {}.to_yaml


    # Serialize share visibilities associated to public posts
    User.find_in_batches do |users|
      users.each do |user|
        results = User.joins(:contact).
                       joins("LEFT OUTER JOIN share_visibilities ON share_visibilities.contact_id = contacts.id").
                       select("share_visibilities.id, share_visibilities.shareable_type").
                       select_all

        User.batch_add_hidden_sharable(results)
      end
    end

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

    # Remove superfluous indexes
    execute <<SQL
      ALTER TABLE share_visibilities
        DROP INDEX index_post_visibilities_on_post_id,
        DROP INDEX shareable_and_hidden_and_contact_id
SQL

  end

  def self.down
    add_index "share_visibilities", ["shareable_id"]
    add_index "share_visibilities", ["shareable_id", "shareable_type", "hidden", "contact_id"]

    remove_column :users, :hidden_shareables
  end
end
