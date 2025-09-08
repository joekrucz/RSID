class DropTodosNotesFileItemsTables < ActiveRecord::Migration[8.0]
  def up
    drop_table :todos, if_exists: true
    drop_table :notes, if_exists: true
    drop_table :file_items, if_exists: true
  end

  def down
    # Note: This migration only drops tables, recreating them would require
    # the original table definitions which are not available
    raise ActiveRecord::IrreversibleMigration
  end
end