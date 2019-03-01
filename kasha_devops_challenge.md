# Migrating wordpress from manual configured AWS to auto scaling AWS high availability

Setup a highly availabile, fault tolerant wordpress architecture as follows:

Having 2 Ec2 instances behind an auto scaling group behind an application loadbalancer. 
Sping up and download code from the WP site, push media assets to Media assets S# 
Cloudfront to access the Images 
MultiAZ database
Terminate EC2 instance, respawn. 
Terminate DB , Multiple AZ will pick up. 
Register a domain name. 

### Step 1: Configure security groups

Two security groups will be needed here:
> SG to allow for public connections to the EC2 instance on port 80 (HTTP) and 22 (SSH) - DMZ SG
> SG to allow the SG above to communicate with RDS inscance - This secures access to the DB from this security group only - RDS SG


### Step 2: Setup RDS

Follow the AWS prompts to setup the RDS database and add to the RDS SG for access to port 3306 from the DMZ SG; 
Production MySQL - Multi AZ 
It is best to have your RDS instance on multiple AZ.
Select RDS SG
This ensures that when one availability zone has an issue, the database can still be accessed on a different AZ - this is not available on the Free tire account. 
Enable Enhanced Monitoring 

### Step 3: Setup S3 buckets

In order to have a smooth migration, we will need to setup 2 buckets.
 - code base bucket (kashadevopswpcode)
 - asset base bucket (kashadevopswpassets)
Grant read access


### Route 53 

To setup route 53, we have the hosted zones where hosted Domain names should be. - I prefered to use aws supplied domain name availble on free tire 

On a hosted dns, however, one would have to cliek on the dns 

Create IAM role with full s3 access 
> EC2 Service
> Full s3 access

### step 4: Launch new ec2 instance (t2.micro should be enough)

When launching the EC2 instance, we add the instance to the DMZ SG in order to get http and ssh access to access the server.
IAM role - the IAM created for full s3 access above

Under the advanced Details, pass the bootstrap script provided 

[kashadevopsbss.sh](https://github.com/badibuddy/devops/blob/master/kashadevopsbss.sh) 

for ubuntu linux distribution

You ca copy paste from below: 

```sh
#!/bin/bash
apt update -y
apt install awscli -y
apt install nginx -y
apt install php-fpm php php-mysql -y
cd /var/www/html
echo "Kashadevops" > kashadevops.html
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
cp -r wordpress/* /var/www/html/
rm -rf wordpress
rm -rf latest.tar.gz
chmod -R 755 /var/www/html/
chown -R www-data:www-data /var/www/html/
systemctl enable nginx
```

Add tag (optional) : standard websvr name tag
Launch EC2 instance. 

### step 5: Configure new EC2
Connect to the EC2 instance using pem file
Confirm all the installations from the bootstrap were doen correctly
A few changes on the default setup for nginx to below: 

```sh	
	location / { 
		try_files $uri $uri/ /index.php?q=$uri&$args; 
	}
	location ~ \.php$ {
                #NOTE: You should have "cgi.fix_pathinfo = 0;" in php.ini
		fastcgi_buffers 8 256k;
		fastcgi_buffer_size 128k;
		fastcgi_intercept_errors on;
		include fastcgi_params;
		fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                fastcgi_pass unix:/var/run/php/php7.2-fpm.sock;
	}
	location /wp-content {
		rewrite ^/wp-content/uploads/(.*)$ http://d1lmxnv1vghp59.cloudfront.net/$1 redirect;
	}
```
This enables wordpress to redirect all media access to the cloudfront dns configured, as opposed to loading this from the EC2 instance (quite small t2.micro )

#### Setup the RDS database

Grab the endpoint for mysql database
Install wordpress following the prompts
Once nstallation complete, setup wordpress as needed.


# What Happened next after installation of wordpress

Edit the post - Hello World
add a few photos - to test media asset folder from S3 later
setup a cronjob running every 5 minutes to sync media asset files to s3 media bucket (this can also be added for the code).

```sh
 crontab -l
# Edit this file to introduce tasks to be run by cron.
# 
# Each task to run has to be defined through a single line
# indicating with different fields when the task will be run
# and what command to run for the task
# 
# To define the time you can provide concrete values for
# minute (m), hour (h), day of month (dom), month (mon),
# and day of week (dow) or use '*' in these fields (for 'any').# 
# Notice that tasks will be started based on the cron's system
# daemon's notion of time and timezones.
# 
# Output of the crontab jobs (including errors) is sent through
# email to the user the crontab file belongs to (unless redirected).
# 
# For example, you can run a backup of all your user accounts
# at 5 a.m every week with:
# 0 5 * * 1 tar -zcf /var/backups/home.tgz /home/
# 
# For more information see the manual pages of crontab(5) and cron(8)
# 
# m h  dom mon dow   command
05 *	* * *	aws s3 sync /var/www/html/wp-content/uploads s3://kashadevopswpassets
```

Now all images are being loaded from cloudfront reducing the load on the small EC2 instance.

# Route53 

Using hosted ones, set an alias record to the loadbalancer, eg 
kasha.devops.com - Alias to LB fqdn (provided by AWS)



# Migrtion procedure
_Assuming the existing wordpress installation is within the same VPC_ 

1. Allow the existing EC2 instance to have full s3 write and read (IAM role was already created) 
2. Copy recursively all the code to the wordpress code bucket, copy all media assets to the media assets s3 bucket. 
	- From the existing EC2 instance with the current running code: Assuming it is running on ubuntu:
	 Install awscli 
	```sh apt install awscli -y
	   aws cp --recursive /var/www/html s3://kashadevopscode 
	   aws cp --recursive /var/www/html/wp-content/uploads s3://kashadevopsassets 
	```
	
3. Since the new EC2 instance already has all the configurations done, this will mean the new EC2 instance will pick
the code from s3 code bucket and start to serve the users. 
4. Redirect the hosted domain A record to poin to the new aplication loadbalancer dns, and the "old" website 
will now be presented from the new setup
5. Configure ssl certificates on the EC2 instance - nginx webserver. 

# Monitoring

AWS allows for monitoring via cloudwatch of Instances CPU usage, Memory usage, Disk I/O and much more. 
I however, like to use a tool called zabbix which does this. I have not configured this on the free tire
setup
