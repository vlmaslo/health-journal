class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.references :provider, null: false, foreign_key: true, index: false
      t.references :client, null: false, foreign_key: true
      t.string :plan, null: false, default: "basic"

      t.timestamps
    end
    add_index :subscriptions, [ :provider_id, :client_id ], unique: true
    add_check_constraint :subscriptions, "plan IN ('basic', 'premium')", name: "subscription_plan_check"
  end
end
