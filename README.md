# Cisco ACI Websocket Monitor

## What is Cisco ACI?

If you have never heard of it, please refer here:
https://www.cisco.com/go/aci

One of the major benefits of Cisco ACI is the ability to configure and also monitor
the entire Datacenter Network infrastructure through a central controller via 
REST API (HTTPS). This is the basis for this tool.

## What is this Websocket thing?

WebSocket protocol is a protocol designed for building a long-lasting bidirectional
communications channel between a client and a server, through which the client 
can receive unsolicited information for events that it is subscribed to.

More information:
https://en.wikipedia.org/wiki/WebSocket

## ACI Managed Objects & Websocket

Cisco ACI provides the ability to subscribe to any ACI Managed Objects through a 
websocket and therefore receive updates on Configuration events, Troubleshooting 
events and really anything else within ACI you can think of.

Almost everything in ACI is a Managed Object and can be subscribed to, such as:
- Access Policies
- Logical Policies (Tenants, VRFs, etc.)
- Faults and Events

## How does this thing work?

This repository contains a Dockerfile and several other files which are copied into
the Docker container at Build time. These files contain scripts, requirements, templates
etc. and can all be inspected and modified if required for your particular setup.

### <span style="color:red">DISCLAIMER: What it does not do.</span>

The setup as delivered through this repository does NOT constitute a full monitoring 
solution, no ELK stack or similar log management and visualization is included.

### <span style="color:green">What it does do.</span>

This tool only subscribes to APIC to get notified when MOs it is subscribed to get modified, 
and then forwards these logs any Monitoring solution you may have, such as ELK or TIG,
as long as that solution can receive JSON over HTTP/S. Alternatively or additionally 
these notifications can be written to file locally. Its purpose is to act as a Websocket
capable forwarder for APIC, since most monitoring solutions are not equipped by default 
to handle this subscription mechanism. It can also be used to provide short term intermediate 
monitoring for specific MOs, for example during a Change Window.

![Figure: ACI Websocket Monitor Connections](https://user-images.githubusercontent.com/68273068/100007789-e09e9680-2dcc-11eb-8b91-22c372be1893.png)

### How it is configured to do that.

The most important file contained in here is the ./inputData/config/config.yml file, 
which contains the configuration for the container that needs to be done to fit your
Use Case. This config file describes essentially three things:
- The connection between the Websocket and APIC Controller
- Which ACI Objects are meant to be monitored
- How the Websocket Container proceeds with the received information/logs

The specific configuration options are explained and shown with examples within the 
config.yml file.

Once the container is built, it needs to be started through Docker and when it is 
started, it will use the data provided within the config.yml file to establish a 
connection to the APIC controller and subscribe to specified MOs. The APIC will 
then send information whenever these types of objects change and the tool will receive
them. It will then either write them to a file or forward the JSON data to another 
REST capable endpoint for processing (such as Logstash etc.) or both. More capabilities
to provide the data in different form will potentially be provided at a later date.

## Prerequisites

The only prerequisite for this tool is a working Docker container host to run the 
container on. It is sensible to have a directory prepared to map into the container 
as a volume, to enable the container to write logs and data to the Host filesystem.

## So how do I do it?

### 1. Update the configuration
First thing to do is to put your desired configuration parameters into the config.yml
file that is described above. Each part of the configuration is described within 
this file.

### 2. Build the image
Once the configuration is updated and ready, the container image must be built. 
It can be built without any parameters, just provide a meaningful name to the image.

Example:
```
$ docker build -t aci_websocket:1.1 .
Sending build context to Docker daemon    150kB
Step 1/10 : FROM python:3.8
 ---> f88b2f81f83a
Step 2/10 : RUN mkdir -p /home/requirements /home/scripts /home/templates /home/config /home/data /home/internal
 ---> Using cache
 ---> ef67eac487ea
Step 3/10 : WORKDIR /home/scripts
 ---> Using cache
 ---> 22211688ccfd
Step 4/10 : COPY ./inputData/requirements/ /home/requirements/
 ---> Using cache
 ---> d087fa06a1e9
Step 5/10 : RUN pip install -r /home/requirements/requirements.txt
 ---> Using cache
 ---> 4e93054469f2
Step 6/10 : COPY ./inputData/scripts/ /home/scripts/
 ---> 0f3c6b127f29
Step 7/10 : RUN chmod +x /home/scripts/start.py
 ---> Running in f6e16681460e
Removing intermediate container f6e16681460e
 ---> 659aa03beca8
Step 8/10 : COPY ./inputData/templates/ /home/templates/
 ---> 031733890fa6
Step 9/10 : COPY ./inputData/config/ /home/config/
 ---> 77779725a95a
Step 10/10 : ENTRYPOINT [ "nohup", "python", "/home/scripts/start.py", "&" ]
 ---> Running in 36c184cdff9a
Removing intermediate container 36c184cdff9a
 ---> b962d5c4953e
Successfully built b962d5c4953e
Successfully tagged aci_websocket:1.1
```

### 3. Run the image
As soon as the image is built, the container itself can be run. It can be run without
any parameters, especially if it is not meant to write its data to local file but 
forward it to a remote REST endpoint (except perhaps -d to run in background).
```
$ docker run -d aci_websocket:1.1
e8677e32bda2bd09efb32614f0cb19be04178d1dadc5fefbb554738118e29deb
$ docker ps -a
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
e8677e32bda2        aci_websocket:1.1   "nohup python /home/…"   9 seconds ago       Up 8 seconds                            zealous_nobel
```
This is all that is required to run the image and have it fulfill its function as 
described above.

If you wish to access the container's log data or the data it writes to file from 
outside the container, it will be necessary to map a local volume into the container.
Please map any local directory you want to use for this purpose to /home/data within
the container (see following examples).

On Windows (Docker for Windows):
```
C:\WINDOWS\system32>docker run -d -v /c/Users/pmathy/Development/aciWebsocketMonitor/outputData:/home/data aci_websocket:1.1
1edf4a04aeb65858f04febbd4d20be2eb870b16d90f973effb229e391c5f017a
```
On Linux-based systems:
```
$ docker run -d -v ./outputData:/home/data aci_websocket:1.1
9be2a6c085a0c1ee6fb943dc3423bffa9233c9542d3c7bb627450aa6fc33fc7a
```

This will enable you to look at the log files as well as potential output files within
the mapped directory.

### <span style="color:green">4. Profit!</span>