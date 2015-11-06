class CreateProjectJobs < ActiveRecord::Migration
  def change
    create_table :project_jobs do |t|
      t.references :project, index: true, null: false, foreign_key: true
      t.references :job, index: true, null: false, foreign_key: true

      t.timestamps null: false
    end
    add_index :project_jobs, [:project_id,:job_id], unique: true
  end
end
