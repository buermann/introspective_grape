class CreateUserProjectJobs < ActiveRecord::Migration
  def change
    create_table :user_project_jobs do |t|
      t.references :user, index: true, foreign_key: true, null: false
      t.references :project, index: true, foreign_key: true, null: false
      t.references :job, index: true, foreign_key: true, null: false

      t.timestamps null: false
    end
    add_index :user_project_jobs, [:user_id,:project_id,:job_id], unique: true
  end
end
