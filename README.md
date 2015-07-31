# tsuru-packer
packer template to create basic tsuru image.

Now we create two images based on stable version (latest release) of
tsuru package, amazon EC2 image and vagrant virtualbox image.

If you don't want to generate your own amazon ami,
just search for `tsuru-stable` in community ami tab on launch instance wizard.

> Currently, it works just in the **us-east-1** region

## Creating images

We use [packer](https://packer.io) to create our images, so you have to
[install packer first](https://packer.io/intro/getting-started/setup.html).
To create all images you have to do:

```
$ make setup
```

```
$ AWS_ACCESS_KEY="" AWS_SECRET_KEY="" packer build tsuru-stable.json
```

If you want to create just one image you have to do:

```
$ packer build -only=[amazon-ebs/vitualbox-ovf] tsuru-stable.json
```

## ROADMAP

* create a public box in Vagrant Cloud, so anyone who want to test tsuru can do
  it quickly.
* add more builders (DigitalOcean, Parallels and Docker) and more tsuru
  versions (nightly and source code).
