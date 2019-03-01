# Welcome to the devops challenge repository

To continue, you will need to have teh following URLs

### Load Balancer public facing DNS
http://kashadevopsalb-1512830521.eu-west-1.elb.amazonaws.com/

The load balancer has the EC2 instance in the target group with health checks

### RDS
The EC2 instance is allowed to connect to the MySQL DB

### S3 buckets
Two buckets created, one for the media assets another for the code

### Cloudfront distribution
Lin the cloudfront distribution to point to the media assets s3 bucket

### EC2 Instance(s)
One has been created for now. This is behind the loadbalancer.
Redirect rule added to nginx to ensure all media is loaded ffrom cloudfront, to reduce load on the server


#### High Availability and Faut tolerance

The ideal architecture (not free tire) would allow for having the RDS in multiple Availability Zones. 
This ensures when an issue happens with the production DB, another region can take over the load. 

Having two EC2 instances and the application load balancer within the Auto scaling group, 
ensures we can scale up or down depending on the number of hits the website receives. 

