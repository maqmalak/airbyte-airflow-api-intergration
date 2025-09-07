# Missing Directory Structures and Fixes

## Summary of Issues Identified and Fixed

1. **Missing temporal/dynamicconfig directory for Airbyte**
   - Created directory structure: `temporal/dynamicconfig`
   - Required by Airbyte temporal service in docker-compose.airbyte.yaml

2. **Missing dbt-athena directory in plugins folder**
   - Created directory: `plugins/dbt-athena`
   - Referenced in docker-compose.airflow.yaml as DBT_PROFILES_DIR

3. **Typo in docker-compose.airflow.yaml**
   - Fixed "airlfow" to "airflow" in volume mapping for airflow.cfg
   - Line 22: Changed `./config/airflow.cfg:/opt/airlfow/airflow.cfg` to `./config/airflow.cfg:/opt/airflow/airflow.cfg`

4. **Missing /tmp/workspace and /tmp/airbyte_local directories**
   - Created both directories as required by Airbyte configuration
   - These are referenced in the .env file for WORKSPACE_ROOT and LOCAL_ROOT

5. **Issues in install.sh script**
   - Fixed typo: "sparkFiels" → "sparkFiles"
   - Removed reference to non-existent "scripts/" directory
   - Ensured proper directory creation commands

## Directory Structure After Fixes

```
.
├── config/
│   └── airflow.cfg
├── dags/
├── images/
├── logs/
├── outputs/
├── plugins/
│   ├── python_extension/
│   │   ├── operators/
│   │   └── __init__.py
│   └── dbt-athena/          ← Created
├── temporal/                 ← Created
│   └── dynamicconfig/       ← Created
└── sparkFiles/              ← Created via install.sh

/tmp/
├── workspace/               ← Created
└── airbyte_local/           ← Created
```

## Verification Commands

To verify all directories exist:
```bash
# Check project directories
ls -la temporal/dynamicconfig
ls -la plugins/dbt-athena
ls -la sparkFiles

# Check tmp directories
ls -la /tmp/workspace
ls -la /tmp/airbyte_local
```

These fixes ensure that the Airflow and Airbyte integration will have all required directory structures in place for proper operation.