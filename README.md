# Blog CMS

This is my CMS for my blog. It's a simple Ghost CMS instance with Tigris Object Storage.

I used the script from [this blog post](https://www.autodidacts.io/host-ghost-mysql8-on-fly-io-free-tier/) to spin up the initial Ghost CMS server and MySQL server.

## Deploying

```bash
fly deploy
```

## Secrets

- database__client
- database__connection__host
- database__connection__user
- database__connection__password
- database__connection__database
- database__connection__port
- storage__s3__secretAccessKey
- storage__s3__accessKeyId
example: 
```bash
fly secrets set database__client=mysql -a ghost-cms
fly secrets set database__connection__host=ghost-cms-mysql.internal -a ghost-cms
fly secrets set database__connection__user=ghost -a ghost-cms
fly secrets set database__connection__password=PASSWORD -a ghost-cms
fly secrets set database__connection__database=ghost -a ghost-cms
fly secrets set database__connection__port=3306 -a ghost-cms
fly secrets set storage__s3__accessKeyId=ACCESSKEYID -a ghost-cms
fly secrets set storage__s3__secretAccessKey=SECRET -a ghost-cms
```

## Resources:

- [Ghost CMS](https://ghost.org/)
- [Tigris S3 Storage](https://fly.storage.tigris.dev/)
- [Fly.io](https://fly.io/)
- [Nathan Willson's Blog Post](https://blog.nathanwillson.com/ghost-blog-with-tigris/)
- [Hosting Ghost with MYSQL Script](https://www.autodidacts.io/host-ghost-mysql8-on-fly-io-free-tier/)
