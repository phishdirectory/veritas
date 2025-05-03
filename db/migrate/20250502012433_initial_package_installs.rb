class InitialPackageInstalls < ActiveRecord::Migration[8.0]
  TEXT_BYTES = 1_073_741_823

  def up
    # Use Active Record's configured type for primary and foreign keys
    primary_key_type, foreign_key_type = primary_and_foreign_key_types

    # Create Active Storage tables
    create_table :active_storage_blobs, id: primary_key_type do |t|
      t.string   :key,          null: false
      t.string   :filename,     null: false
      t.string   :content_type
      t.text     :metadata
      t.string   :service_name, null: false
      t.bigint   :byte_size,    null: false
      t.string   :checksum

      if connection.supports_datetime_with_precision?
        t.datetime :created_at, precision: 6, null: false
      else
        t.datetime :created_at, null: false
      end

      t.index [ :key ], unique: true
    end

     create_table :ahoy_clicks do |t|
      t.string :campaign, index: true
      t.string :token
    end

    create_table :ahoy_messages do |t|
      t.references :user, polymorphic: true
      t.text :to_ciphertext
      t.string :to_bidx, index: true
      t.string :mailer
      t.text :subject
      t.datetime :sent_at
    end

    add_column :ahoy_messages, :campaign, :string
    add_index :ahoy_messages, :campaign

    create_table :active_storage_attachments, id: primary_key_type do |t|
      t.string     :name,     null: false
      t.references :record,   null: false, polymorphic: true, index: false, type: foreign_key_type
      t.references :blob,     null: false, type: foreign_key_type

      if connection.supports_datetime_with_precision?
        t.datetime :created_at, precision: 6, null: false
      else
        t.datetime :created_at, null: false
      end

      t.index [ :record_type, :record_id, :name, :blob_id ], name: :index_active_storage_attachments_uniqueness, unique: true
      t.foreign_key :active_storage_blobs, column: :blob_id
    end

    create_table :active_storage_variant_records, id: primary_key_type do |t|
      t.belongs_to :blob, null: false, index: false, type: foreign_key_type
      t.string :variation_digest, null: false

      t.index [ :blob_id, :variation_digest ], name: :index_active_storage_variant_records_uniqueness, unique: true
      t.foreign_key :active_storage_blobs, column: :blob_id
    end

    # Create Auditing tables
    create_table :audits1984_audits do |t|
      t.integer :status, default: 0, null: false
      t.text :notes
      t.references :session, null: false
      t.references :auditor, null: false

      t.timestamps
    end

    # Create Console1984 tables
    create_table :console1984_sessions do |t|
      t.text :reason
      t.references :user, null: false, index: false
      t.timestamps

      t.index :created_at
      t.index [ :user_id, :created_at ]
    end

    create_table :console1984_users do |t|
      t.string :username, null: false
      t.timestamps

      t.index [ :username ]
    end

    create_table :console1984_commands do |t|
      t.text :statements
      t.references :sensitive_access
      t.references :session, null: false, index: false
      t.timestamps

      t.index [ :session_id, :created_at, :sensitive_access_id ], name: "on_session_and_sensitive_chronologically"
    end

    create_table :console1984_sensitive_accesses do |t|
      t.text :justification
      t.references :session, null: false

      t.timestamps
    end

    # Add PgSearch dmetaphone support functions - wrap in safety_assured for Strong Migrations
    safety_assured do
      # First enable the extension that provides dmetaphone
      execute "CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;"

      execute <<~'SQL'.squish
        CREATE OR REPLACE FUNCTION pg_search_dmetaphone(text) RETURNS text LANGUAGE SQL IMMUTABLE STRICT AS $function$
          SELECT array_to_string(ARRAY(SELECT dmetaphone(unnest(regexp_split_to_array($1, E'\\s+')))), ' ')
        $function$;
      SQL
    end

    # Create PgSearch documents table
    create_table :pg_search_documents do |t|
      t.text :content
      t.belongs_to :searchable, polymorphic: true, index: true
      t.timestamps null: false
    end

    # Create Versions table for PaperTrail
    create_table :versions do |t|
      t.string   :whodunnit
      t.datetime :created_at
      t.bigint   :item_id,   null: false
      t.string   :item_type, null: false
      t.string   :event,     null: false
      t.text     :object, limit: TEXT_BYTES
    end
    add_index :versions, %i[item_type item_id]

    # Create Lockbox audits table
    create_table :lockbox_audits do |t|
      t.references :subject, polymorphic: true
      t.references :viewer, polymorphic: true
      t.jsonb :data
      t.string :context
      t.string :ip
      t.datetime :created_at
    end

    # Create Ahoy tables
    create_table :ahoy_visits do |t|
      t.string :visit_token
      t.string :visitor_token
      t.references :user
      t.string :ip
      t.text :user_agent
      t.text :referrer
      t.string :referring_domain
      t.text :landing_page
      t.string :browser
      t.string :os
      t.string :device_type
      t.string :country
      t.string :region
      t.string :city
      t.float :latitude
      t.float :longitude
      t.string :utm_source
      t.string :utm_medium
      t.string :utm_term
      t.string :utm_content
      t.string :utm_campaign
      t.string :app_version
      t.string :os_version
      t.string :platform
      t.datetime :started_at
    end

    add_index :ahoy_visits, :visit_token, unique: true
    add_index :ahoy_visits, [ :visitor_token, :started_at ]

    create_table :ahoy_events do |t|
      t.references :visit
      t.references :user
      t.string :name
      t.jsonb :properties
      t.datetime :time
    end

    add_index :ahoy_events, [ :name, :time ]
    add_index :ahoy_events, :properties, using: :gin, opclass: :jsonb_path_ops

    # Create Blazer tables
    create_table :blazer_queries do |t|
      t.references :creator
      t.string :name
      t.text :description
      t.text :statement
      t.string :data_source
      t.string :status
      t.timestamps null: false
    end

    create_table :blazer_audits do |t|
      t.references :user
      t.references :query
      t.text :statement
      t.string :data_source
      t.datetime :created_at
    end

    create_table :blazer_dashboards do |t|
      t.references :creator
      t.string :name
      t.timestamps null: false
    end

    create_table :blazer_dashboard_queries do |t|
      t.references :dashboard
      t.references :query
      t.integer :position
      t.timestamps null: false
    end

    create_table :blazer_checks do |t|
      t.references :creator
      t.references :query
      t.string :state
      t.string :schedule
      t.text :emails
      t.text :slack_channels
      t.string :check_type
      t.text :message
      t.datetime :last_run_at
      t.timestamps null: false
    end

    # Create Blazer uploads table
    create_table :blazer_uploads do |t|
      t.references :creator
      t.string :table
      t.text :description
      t.timestamps null: false
    end

    # Create Flipper tables
    create_table :flipper_features do |t|
      t.string :key, null: false
      t.timestamps null: false
    end
    add_index :flipper_features, :key, unique: true

    create_table :flipper_gates do |t|
      t.string :feature_key, null: false
      t.string :key, null: false
      t.text :value
      t.timestamps null: false
    end
    add_index :flipper_gates, [ :feature_key, :key, :value ], unique: true, length: { value: 255 }

    # Create FriendlyId tables
    create_table :friendly_id_slugs do |t|
      t.string :slug, null: false
      t.integer :sluggable_id, null: false
      t.string :sluggable_type, limit: 50
      t.string :scope
      t.datetime :created_at
    end
    add_index :friendly_id_slugs, [ :sluggable_type, :sluggable_id ]
    add_index :friendly_id_slugs, [ :slug, :sluggable_type ], length: { slug: 140, sluggable_type: 50 }
    add_index :friendly_id_slugs, [ :slug, :sluggable_type, :scope ], length: { slug: 70, sluggable_type: 50, scope: 70 }, unique: true
  end

  def down
    # Drop FriendlyId tables
    drop_table :friendly_id_slugs

    # Drop Flipper tables
    drop_table :flipper_gates
    drop_table :flipper_features

    # Drop Blazer tables
    drop_table :blazer_uploads
    drop_table :blazer_checks
    drop_table :blazer_dashboard_queries
    drop_table :blazer_dashboards
    drop_table :blazer_audits
    drop_table :blazer_queries


    remove_index :ahoy_messages, :campaign if index_exists?(:ahoy_messages, :campaign)


    # Drop Ahoy tables
  drop_table :ahoy_events if table_exists?(:ahoy_events)
  drop_table :ahoy_visits if table_exists?(:ahoy_visits)
  drop_table :ahoy_messages if table_exists?(:ahoy_messages)
  drop_table :ahoy_clicks if table_exists?(:ahoy_clicks)


    # Drop Lockbox audits table
    drop_table :lockbox_audits

    # Drop Versions table
    drop_table :versions

    # Drop PgSearch documents table
    drop_table :pg_search_documents

  safety_assured do
    # Check if the function exists before dropping it
    function_exists = connection.execute("SELECT EXISTS(SELECT 1 FROM pg_proc WHERE proname = 'pg_search_dmetaphone')").first["exists"]

    if function_exists
      execute <<~'SQL'.squish
        DROP FUNCTION pg_search_dmetaphone(text);
      SQL
    end

    execute <<~'SQL'.squish
      DROP EXTENSION IF EXISTS fuzzystrmatch;
    SQL
  end

    # Drop Console1984 tables
    drop_table :console1984_sensitive_accesses
    drop_table :console1984_commands
    drop_table :console1984_users
    drop_table :console1984_sessions

    # Drop Auditing tables
    drop_table :audits1984_audits

    # Drop Active Storage tables
    drop_table :active_storage_variant_records
    drop_table :active_storage_attachments
    drop_table :active_storage_blobs
  end

  private
    def primary_and_foreign_key_types
      config = Rails.configuration.generators
      setting = config.options[config.orm][:primary_key_type]
      primary_key_type = setting || :primary_key
      foreign_key_type = setting || :bigint
      [ primary_key_type, foreign_key_type ]
    end
end
