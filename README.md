# Scalable and reproducible workflows with Pachyderm
In this page we introduce an metabolomics preprocessing workflow that you can run using [Pachyderm](https://github.com/pachyderm/pachyderm), a distributed data-processing tool built on software containers that enables scalable and reproducible pipelines.

## Relevant sources of information

- [Pachyderm Helm Chart](https://github.com/kubernetes/charts/tree/master/stable/pachyderm) A Helm Chart for deploying Pachyderm on Kubernetes as a service
- [Pachyderm Documentation](http://docs.pachyderm.io/en/v1.7.3/index.html) Official documentation of Pachyderm
- [Kubernetes cheatsheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/) Basic Kubernetes client commands
- [Creating a R microservice](https://hub.docker.com/_/r-base/) Tips for creating a R Docker image
- [Pachyderm publication](https://doi.org/10.1093/bioinformatics/bty699) Container-based bioinformatics with Pachyderm

## Set up the Kubernetes infrastructure

For starting up a local Kubernetes cluster run:
```bash
> sudo minikube start --vm-driver=none
```
Deploy the Kubernetes Package Manager on your newly instantiated cluster:  
```bash
> sudo helm init
```
Deploy Pachyderm as a service on your cluster:
```bash
> sudo helm install --namespace pachyderm --name my-release stable/pachyderm
```

Please note that the last two commands may take a little while to complete. Take a look at how Helm works. What are each of the arguments that we pass to the install command?

## Hands-on with Pachyderm

### Useful information
The most common way to interact with Pachyderm is by using the Pachyderm Client (pachctl). You can explore the different commands available by using:
```bash
> pachctl  --help
```
And if you need more information about a particular command please use:
```bash
> pachctl <name of the command> --help
```

### Ingest the dataset from MetaboLights

Note that for uploading the data to the `PFS`, it is advisable to interact with Pachyderm from the provided VM.

1. Start by cloning this repository:
```bash
> git clone https://github.com/jonandernovella/gridka-pachyderm
> cd gridka-pachyderm/download
```

2. Ingest the dataset using the provided bash script:
```bash
# Dataset retrieval
> sh download-ms1.sh
> sh download-ms1-2.sh
```

### Add the dataset to the Pachyderm File System (PFS)

A repo is the highest level data primitive in Pachyderm. They should be dedicated to a single source of data such as the input from a particular tool. Examples include training data for an ML model or genome annotation data.
Here we will create a single repo which will serve as input for the first step of the workflow:
```bash
> pachctl create-repo mrpo
```
You can push data into this repository using the put-file command. This will create a new commit, add data, and finish the commit. Explore further on how commits work. First navigate to ms1: 
```bash
> cd ./ms1
```
Now push the data into the repository you created in the previous step:
```bash
> pachctl put-file <name of the repo> <name of the branch> -c -r -p <number of files to upload in parallel> -f .
```
This will create a new commit on the repository including the data we previously downloaded.

### Running a Pachyderm pipeline

Once your data is in the repository, you are ready to start a bunch of pipelines cranking through data in a distributed fashion. Pipelines are the core processing primitive in Pachyderm and they’re specified with a JSON encoding. Explore the pipelines folder and find out which of the pipelines is the first step of the pre-processing workflow. You can find it by discovering which pipeline has the previously created repository as an input. Have a look at the input section in the JSON files in the `pipelines` folder:
```JSON
 "input": {
    "atom": {
      "repo": "",
      "glob": ""
    }
  }
```
Which one reads from the original repository and not from other tools? Figure it out and then run it using:
```bash
> pachctl create-pipeline -f <JSON file>
```
What happens after you create a pipeline? Creating a pipeline tells Pachyderm to run your code on every finished commit in a repo as well as all future commits that happen after the pipeline is created. Our repo already had a commit, so Pachyderm automatically launched a job (Kubernetes pod) to process that data. This first time it might take some extra time since it needs to download the image from a container image registry. You can view the pipeline status and its corresponding jobs using:
```bash
> pachctl list-job
```
and 

```bash
> pachctl list-pipeline
```
And explore the different worker pods in your Kubernetes cluster via:
```bash
> kubectl get pods -o wide
```
Try changing some parameters such as the parallelism specification, resource specification and glob pattern. What is happening? How many pods are scheduled? Play with the parameters and try to understand what happens. You can learn about the different settings in the Pachyderm Documentation.

You can re-run the pipeline with a new pipeline definition (new parameters etc) like this:
```bash
> pachctl update-pipeline -f <JSON file> --reprocess
```
Four more pipelines compose the pre-processing workflow. Find your way and run the rest of the pipeline (TextExporter is the last step). After you run the entire workflow, the resulting CSV file generated by the TextExporter in OpenMS will be saved in the TextExporter repository. You can download the file simply by using:
```bash
> pachctl get-file TextExporter <commit-id> <path-to-file-in pachd> > <custom-name-of-file>
```
The <commit-id> is easily obtainable by checking the most recently made commit in the TextExporter repository using:
```bash
> pachctl list-commit TextExporter
```
Also, the <path-to-file> can be obtained by checking the list of files outputted to the TextExporter repository at a specific branch. To which branch does Pachyderm make commits by default?
```bash
> pachctl list-file <name-of-repo> <branch-name>
```
### Data versioning in Pachyderm
Pachyderm uses a Data Repository within its File System. This means that it will keep track of different file versions over time, like Git. Effectively, it enables the ability to track the provenance of results: results can be traced back to their origins at any time point.

Pipelines automatically process the data as new commits are finished. Think of pipelines as being subscribed to any new commits on their input repositories. Similarly to Git, commits have a parental structure that tracks which files have changed. In this case we are going add some more metabolite data files.

Let’s create a new commit in a parental structure. To do this we will simply do two more put-file commands with -c and by specifying master as the branch, it will automatically parent our commits onto each other. Branch names are just references to a particular HEAD commit.
```bash
> cd ./ms1-2
```
```bash
> pachctl put-file <name of the repo> <name of the branch> -c -r -p <number of files to upload in parallel> -f .
```
Did any new job get triggered? What data is being processed now? All available data or just new data? Explore which new commits have been made as a result of the new input data. 
```bash
> pachctl list-commit <repo-name>
```

> **Challenge:** Read the Pachyderm publication carefully and try to compute the speedup of one of the stages of the workflow.

You can inspect additional information about a job like this:
```bash
> pachctl inspect-job <job-id> --raw
```


## Implementing your own microservice in a pipeline

In this section we show you how wrap your own script around a Docker image and integrate it into your workflow using Pachyderm.

First, write a script in your favorite programming language. For simplicity, it is advisable that you write it in bash or R. In order to create a Docker container you can follow the scheme recommended by PhenoMeNal (for guidance see the dockerized [xcms R package](https://github.com/phnmnl/container-xcms). The required packages must be installed. Your script should be placed in a separate folder which is added to the appropriate folder inside the container and granted execution permission. Now, all you need to do in order to wrap your script in a Docker image is to write a [Dockerfile](https://docs.docker.com/engine/reference/builder/). In order to do that, please have a look at the Dockerfile in the example.


```Docker
FROM <base-image>
MAINTAINER Name Surname, myemail@domain.de

# Fill out the lines by looking at the given example
RUN #### install the needed packages
ADD #### add all scripts to container
RUN #### give execution permission to the scripts
ENTRYPOINYT #### give an entrypoint to your container
```

In the Dockerfile you first specify a base image that you want to start **FROM**. If you are working to an R-based service, the base image *r-base* is a good choice, as it includes all of the dependencies you need to run your script. Then, you provide the **MAINTAINER**, that is typically your name and a contact.

The next two lines in the Dockerfile are the most important. The **ADD** instruction serves to add a file in the build context to a directory in your Docker image. In fact, you can use it to add your script in the root directory. The **RUN** instruction, specifies which command to execute and commits the results, when the container will be started.

When you are done with the Dockerfile, you need to build the image. The `docker build` command does the job. 

```bash
> docker build -t <image-name> <path-to-docker-file>
```

Withs the previous command you build the image, specifying its name and the directory of the build context. To successfully run this command, it is very important that the build context contains both the *Dockerfile* and folder with your script. If everything works fine it will say that the image was successfully built.

To verify that your image works correctly and as excpected, you can use the `docker run` command, which serves to run a service that has been previously built.

```bash
> docker run -v /host/directory/data:/data <image-name> <args>
```

In the previous command the `-v` argument is used to specify a directory on our host machine, that will be mounted on the Docker container (note that the full path needs to be provided). The image name and execution arguments need to be passed to this command.

You can read more on how to develop Docker images on the Docker [documentation](https://docs.docker.com/). 

### Integrate your new container to the pipeline
If you managed to successfully build the your Docker image, it should now be part of the local image registry. You can check this by using the command `docker images`.

> **Tip:** Have a look at the JSON files located in the *pipelines* folder. You will need to create a new one that reads the output from a repository.

Good luck!
