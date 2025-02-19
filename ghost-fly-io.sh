# Prompt for app name
echo -n "Enter App Name: " && \
read appname && \
echo -n "Enter MYSQL password: " && \
read mysqlpassword && \
echo -n "Enter MYSQL Root password: " && \
read mysqlrootpassword && \
# Heredoc wrapper for tidyness (starting now, because we can't seem to prompt for input within heredoc)
bash << EOF
# Uncomment following line for debugging (prints each command before running)
set -x
# Check if Fly CLI is installed, and install it if it isn't
# Inspect script first if you are leery of pipe-to-bash
command -v flyctl >/dev/null 2>&1 || { echo >&2 "Fly CLI required and not found. Installing..."; curl -L https://fly.io/install.sh | sh; }
# This will open a browser, where you can enter a username and password, and your credit card (which is required even for free tier, for fraud prevention).
flyctl auth signup
# Create a directory for the project and enter it, since the next command will output a file
mkdir ghost-flyio && cd ghost-flyio
# Create an app -- using Ghost docker image, Seattle region, and app name prompted for earlier -- but don't deploy it
flyctl launch --name $appname --image=ghost:5-alpine --vm-memory 512 --region sea --no-deploy --org personal
# Provision a volume for Ghost's content
# Size can be up to 3GB and still fit in the free plan, but 1GB will be enough for starters.
flyctl volumes create ghost_data --region sea --size 1 --auto-confirm
# Install sed (stream editor), if it isn't already installed
command -v sed >/dev/null 2>&1 || { echo >&2 "sed (Stream EDitor) required and not found. Installing..."; sudo apt install sed; }
# Update the port to Ghost's default (2368)
sed -i 's/internal_port = 8080/internal_port = 2368/g' fly.toml
sed -i 's/min_machines_running = 0/min_machines_running = 1/g' fly.toml
# Append info about where to find the persistent storage to fly.toml
cat >> fly.toml << BLOCK
[mounts]
  source="ghost_data"
  destination="/var/lib/ghost/content"
BLOCK
# Set Ghost url
flyctl secrets set url=https://$appname.fly.dev
# Spin up a second instance for our database server
mkdir ghost-flyio-mysql && cd ghost-flyio-mysql
# Create an app for our mysql
flyctl launch --name ${appname}-mysql --image=mysql:8 --vm-memory 512 --region sea --no-deploy --org personal  
# Create a persistent volume for our MYSQL data
fly volumes create mysql_data --size 2 --region sea --auto-confirm
fly secrets set MYSQL_PASSWORD=$mysqlpassword MYSQL_ROOT_PASSWORD=$mysqlrootpassword
# Add our database credentials to the Ghost instance
fly secrets set database__client=mysql -a $appname
fly secrets set database__connection__host=${appname}-mysql.internal -a $appname
fly secrets set database__connection__user=ghost -a $appname
fly secrets set database__connection__password=$mysqlpassword -a $appname
fly secrets set database__connection__database=ghost -a $appname
fly secrets set database__connection__port=3306 -a $appname
fly secrets set NODE_ENV=production
cat > fly.toml << BLOCK2  
app = "$appname-mysql"
primary_region = 'sea'
[build]
  image = 'mysql:8'
[env]
  MYSQL_DATABASE = 'ghost'
  MYSQL_USER = 'ghost'
[processes]
  app = '--datadir /data/mysql --mysql-native-password=ON  --performance-schema=OFF --innodb-buffer-pool-size 64M'
[[mounts]]
  source = 'mysql_data'
  destination = '/data'
[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = 'stop'
  auto_start_machines = true
  min_machines_running = 1
  processes = ['app']
[[vm]]
  memory = '512mb'
  cpu_kind = 'shared'
  cpus = 1
BLOCK2
# Note: if you aren't trying to stay within the free tier, you might want to remove the performance schema and buffer pool size flags above.
# sed -i 's/min_machines_running = 0/min_machines_running = 1/g' fly.toml
# Deploy MySQL server.
# If you aren't trying to stay within the free tier, uncomment this to give the MYSQL VM 2GB of ram
# fly scale memory 2048
flyctl deploy
cd ../
# Deploy Ghost application server
flyctl deploy
# Boom! We're airborne.
# End our bash Heredoc
EOF