# ASL 
This project has several parts:
* A data collection pipeline
* A model training pipeline
* An app to classify sign language

## Dependencies

### Docker  :smile::whale:
* Install
  * [windows download](https://docs.docker.com/docker-for-windows/install/)
  * [macOS download](https://docs.docker.com/docker-for-mac/install/)
  * [ubuntu download](https://docs.docker.com/install/linux/docker-ce/ubuntu/)

### Ngrok
  * [windows download](https://ngrok.com/download)
  * [macOS download](https://ngrok.com/download)


## Run Data Capture Pipeline

### Start Server
1. open a terminal and navigate to **server** directory
2. run the following command
    ```bash
    docker-compose up
    ```

### Start Ngrok
1. open a terminal and navigate to **server** directory
2. run the following command
    ```bash
    ngrok http 5555
    ```

### Open Xcode `Data Capture` Project
1. open a terminal and navigate to **ASLDataCaptureApp** directory
2. open the `.xcodeproj` file
3. change the developer team in the signing & capabilities settings
4. load onto your device



