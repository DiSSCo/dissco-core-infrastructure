This directory contains the infrastructure files for the Handle and DOI servers. 

# Handles Vs DOIs
Many objects within DiSSCO get a persistent identifier. Digital Specimens and Media Objects are intended to be cited in research, so they receive a DOI. Other objects, such as Annotations, Source Systems, and Machine Annotation Services, get Handles instead.

The DOI and Handle infrastructures are managed separately from DiSSCo and from each other for security purposes. 

Both DOIs and Handles rely on the Handle protocol. 

# Components of the Infrastructure

## Server
There are two servers, one for the resolution of DOIs, and one for the resolution of Handles. The DOI server is associated with the prefix 10.5555.22.1, and the Handle Server is associated with the prefix 20.5000.1025. Each server is deployed on a separate EC2 instance.

## Database
We have enabled custom storage solutions for our PID infrastructure. Both servers read from a MongoDB DocumentStore. 

The DOI storage is kept separate from the DiSSCo infrastructure, while Handles are managed in a DocumentStore with other DiSSCo objects. This is to allow for the possibility of other infrastructures minting DOIs for their Digital Specimens and Media Objets external to DISSCo. Objects that get Handles are DiSSCo-specific, so keeping storage separate is not necessary. 

In both cases, there is a document store for each environment: Test, Acceptance, and Production. Only production PIDs are resolvable; in Test and Acceptance, they are given the prefixes "TEST" and "SANDBOX", which prevents the server from resolving them. 

## Network


## API
A custom API, deployed on the DiSSCo Kubernetes clusters, interfaces with 

# Handle Server Installation and Deployment Guide

This section is meant to serve as a quick reference on setting up a Handle Server.
Further details of the Handle software are found in the [Handle Technical Manual](http://www.handle.net/tech_manual/HN_Tech_Manual_9.pdf).

## Requirements

1. You must have a registered prefix with CNRI in order to deploy your own Handle Server.
2. The Handle software requires at least Java version 8 to run.
3. Docker must be installed on your machine.

## Installation

### 1. Install and Unpack the Handle Software Release

The CNRI Handle software is available [here](http://handle.net/download_hnr.html).

### 2. Run the Handle Setup Program

Navigate to the "handle-9.0.0" directory and execute the following commands:

- On Unix-like systems: `bin/hdl-setup-server /hs/svr_1`
- On Windows systems: `bin\hdl-setup-server.bat \hs\svr_1`

When running the startup program, make sure that your public IP is the address the handle server will be exposed to (default is the private ip address).

***Once you run the setup program, you will need to email the sitebndl.zip file to hdladmin@cnri.reston.va.us***

### 3. Set Up the Handle Server

In the `config.dct` file, you will need to replace “NA/YOUR_PREFIX” with the prefix allocated to you by CNRI. There are three places to change (all in the `server_config` section of `config.dct`): server_admins, replication_admins, and “autohomed_prefixes”.

If using PostgreSQL as storage instead of the default, add PostgreSQL configuration in `server_config` section.

The `server_config` section should thus look like:
```
"server_config" = {
    "server_admins" = (
        "300:0.NA/{YOUR PREFIX}"
    )
	"replication_admins" = (
  	    "300:0.NA/YOUR PREFIX}"
	)
	"max_session_time" = "86400000"
	"this_server_id" = "1"
	"max_auth_time" = "60000"
	"server_admin_full_access" = "yes"
	"case_sensitive" = "no"
	"auto_homed_prefixes" = (
  	"0.NA/{YOUR PREFIX}"
	)
    "storage_type"="sql"
    "sql_settings"={
        "sql_url"="{YOUR VALUE}"
        "sql_driver"="org.postgresql.Driver"
        "sql_login"="{YOUR VALUE}"
        "sql_passwd"="{YOUR VALUE}"
        "sql_read_only"="no"
        "trace_sql"="yes"
    }
}
```

Because we set up our Handle server to be exposed to the public IP address in the setup program, we
want to make sure the bind address in `confic.dct` is the **private** IP address. You will have to change the `hdl_tcp_config` and `hdl_udp_config` sections.
The public IP address will be automatically populated in the `siteinfo.json` file.

### 4. Storage

This section describes how to set up a PostgreSQL database for Handle storage. More information can be found in the [Handle Techincal Manual](http://www.handle.net/tech_manual/HN_Tech_Manual_9.pdf).

Note: When you start the handle server, you must have the JDBC driver for your database in your classpath. Place the jar file (e.g. postgresql8jdbc3.jar) in the lib subdirectory of the unzipped Handle.Net distribution.

You can use the psql shell to create the database. Make sure you have a table called `handles` and a table called `nas`.

Create the database and make sure that it uses Unicode:
```
createdb -O handleserver -E unicode handleDatabase
```
Create the following tables:

```
psql -h yourservername -U handleserver -d handlesystem
create table nas (na bytea not null, primary key(na));
create table handles (handle bytea not null, idx int4 not
null, type bytea, data bytea, ttl_type int2, ttl int4, timestamp int4, refs text, admin_read bool,
admin_write bool, pub_read bool,
pub_write bool, primary key(handle, idx));
create index dataindex on handles ( data );
create index handleindex on handles ( handle );
grant all on nas,handles to handleserver;
grant select on nas,handles to public;
\q
```

The `nas` table should have the following single entry:

```
0.NA/{Your prefix}
```

### 5. Firewalls
Make sure port 8000 and port 2641 are open to all traffic on the machine you are running the Handle Server on.
You’ll also need to give the Handle Server network access to your database storage.

## Deploying the Application

Now that your Handle Server has been initialized, it's time to deploy.

### 1. Move keys

The following files have sensitive information and should be moved out of the directory that was created when you initialized the Handle Server:
- ampriv.bin
- config.dct
- privkey.bin
- serverCertificate.pem
- sitebndl.zip
- siteinfo.json

Define the absolute path of where you moved these files in your .env file (SRC_KEYS).

### 2. Build and Deploy the Image

Put the Dockerfile and compose.yaml on the top level of your machine. Build the image of your Handle server using the Dockerfile, and deploy it using docker compose (make sure to change the image name in the compose file).

Done! A successful deployment will look like:
```
Handle.Net Server Software version 9.3.0
HTTP handle Request Listener:
    address: {PRIVATE IP ADDRESS}
        port: 8000
UDP handle Request Listener:
    address: {PRIVATE IP ADDRESS}
        port: 2641
Starting HTTP server...
TCP handle Request Listener:
    address: {PRIVATE IP ADDRESS}
        port: 2641
Starting TCP request handlers...
Starting UDP request handlers...
```