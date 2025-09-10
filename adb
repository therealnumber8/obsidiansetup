mkdir -p databricks-jobs-export

# List all jobs and save to file
databricks jobs list --output JSON > databricks-jobs-export/jobs-list.json

# Export each job configuration
databricks jobs list --output JSON | jq -r '.jobs[].job_id' | while read job_id; do
    echo "Exporting job ID: $job_id"
    databricks jobs get $job_id --output JSON > databricks-jobs-export/job-$job_id.json
done

for job_file in databricks-jobs-export/job-*.json; do
    echo "Importing $job_file"
    
    # Remove job_id and created_time from the JSON (these are auto-generated)
    cat $job_file | jq 'del(.job_id, .created_time, .creator_user_name)' > temp-job.json
    
    # Create the job in target workspace
    databricks jobs create --json @temp-job.json
done
