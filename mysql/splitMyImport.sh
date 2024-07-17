#!/bin/bash
#This shell script is designed to import databases from a provided MySQL dump file in parallel,
#with a limit on the maximum number of concurrent jobs.
#WARNING: THE DBs TO BE IMPORTED MUST BE PRESENT ON THE LOCAL ENGINE!

dump_file="$1"

# Check if the dump file was provided
if [ -z "$dump_file" ]; then
  echo "Usage: $0 <dump_file>"  # Display correct usage message
  exit 1  # Exit with an error code
fi

# Maximum number of parallel jobs (you can adjust this as needed)
max_jobs=4

# Get the list of databases to exclude
exclude_dbs="sys|information_schema|performance_schema|database"

# List databases and filter out those to exclude
databases=$(mysql -e "SHOW DATABASES" | grep -vE "$exclude_dbs" | sort -r)

# Function to import a single database
import_db() {
  db=$1  # Assign parameter to the 'db' variable
  echo "Importing database: $db"  # Message indicating the start of the import
  mysql --one-database "$db" < "$dump_file"  # Import the dump file into the specified database
  if [ $? -eq 0 ]; then  # Check if the previous command succeeded
    echo "Import of $db completed"  # Success message
  else
    echo "Error during the import of $db"  # Error message
  fi
}

# Counter for active jobs
active_jobs=0

# Execute imports in parallel
for db in $databases; do
  import_db "$db" &  # Start the database import in the background

  # Increment the active jobs counter
  active_jobs=$((active_jobs + 1))

  # If the number of active jobs reaches the maximum, wait for one to finish
  if [ "$active_jobs" -ge "$max_jobs" ]; then
    wait -n  # Wait for any of the background jobs to complete
    active_jobs=$((active_jobs - 1))  # Decrement the active jobs counter
  fi
done

# Wait for all jobs to finish
wait  # Wait for all background jobs to complete
