#!/bin/bash

export "DB_USERNAME=lucas"
export "DB_PASSWORD=$(terraform output -raw user_password)"
export "DB_HOST=$(terraform output -raw domain)"
export "DB_PORT=$(terraform output -raw port)"
export "DB_NAME=defaultdb"
export "DB_TYPE=mysql+pymysql"
