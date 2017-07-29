# AWS rekognition quick start

With Rekognition, your applications can detect objects, scenes, and faces in images. With this rich context and information, you can enable visual search, discovery, and authentication in your applications.

## Case1: Face authentication with recognition service

Lets try to use AWS recognition service to perform a face authentication.
To start we would need to follow a sequence of simple steps:
* First we need to create an S3 bucket (if you dont have it yet). S3 bucket is needed to put some images from the first place and later index them.
* Secondly, we need to create an recognition image collection which will be used to store extracted, searchable image vectors.
* That is, having done first 2 steps we can start using search-faces-by-image feature, to detect/recognise knowable images (indexed) from the newly created picture

### Create s3 bucket to store faces of your friends

```bash 
# Note: bucket must be in the same region as rekognition service (us-east-1 for example)
aws s3api create-bucket --bucket <bucket-name> --region us-east-1

# List available buckets
aws s3 ls
```

### Upload images into created bucket
```bash
aws s3 cp image-path-local.png s3://<bucket-name>/<path-remote>/
```

### Create aws rekognition collection

A collection is a container for persisting faces detected by the IndexFaces API.

You might create a collection to store scanned badge images using the IndexFaces operation, which extracts faces and stores them as searchable image vectors. When an employee enters the building, an image of their face is captured and sent to the SearchFacesByImage operation. If the face match produces a sufficiently high similarity score, the employee is immediately verified. As a developer of identity verification system, you might use a 99% similarity score.

```bash
# Create new recognition collection
aws rekognition create-collection --collection-id <collection-id> --region us-east-1

# List collections
aws rekognition list-collections \
    --region us-east-1

# Delete collecion
aws rekognition delete-collection --collection-id test-collection --region us-east-1

```

### Index uploaded images

```bash
# index faces from s3 bucket
aws rekognition index-faces \
    --region us-east-1 \
    --image "{\"S3Object\":{\"Bucket\":\"friends-faces\",\"Name\":\"img-name.png\"}}" \
    --collection-id "friends" \
    --detection-attributes "ALL" \
    --external-image-id "img-name.png"

# api: http://docs.aws.amazon.com/rekognition/latest/dg/API_IndexFaces.html

# show indexeed faces
aws rekognition list-faces \
    --collection-id friends \
    --region us-east-1

```

### Recognise 

```bash
# search faces on the image
aws rekognition search-faces-by-image \
    --collection-id "friends" \
    --image "{\"S3Object\":{\"Bucket\":\"friends-faces\",\"Name\":\"to-detect/face-to-detect.png\"}}"\
    --region us-east-1

```

Expected service response
```json
{
  "SearchedFaceBoundingBox": {
    "Width": 0.6401326656341553,
    "Height": 0.42888888716697693,
    "Left": 0.11442785710096359,
    "Top": 0.1599999964237213
  },
  "SearchedFaceConfidence": 99.9922866821289,
  "FaceMatches": [
    {
      "Similarity": 99.98460388183594,
      "Face": {
        "FaceId": "a501aa4a-f2f6-5ad2-8b49-f956a2db98b7",
        "BoundingBox": {
          "Width": 0.6401330232620239,
          "Height": 0.4288890063762665,
          "Left": 0.11442799866199493,
          "Top": 0.1599999964237213
        },
        "ImageId": "33217f82-889b-526f-89cb-aea3abc8d231",
        "ExternalImageId": "image-name",
        "Confidence": 99.99230194091797
      }
    }
  ]
}
```

All matched faces can be found in FaceMatches collection

To help us manage json response, you can use [jq tool](https://stedolan.github.io/jq/tutorial/)
For example, to get a SearchedFaceConfidence from the service response, we can use: `service-call > jq '.SearchedFaceConfidence'` 
Expected result must be something like that: 99.9922866821289

To get the first matched face with a highest confidence: `service-call > | jq '.FaceMatches[0].Face.ExternalImageId'`
Expected result: image-external-name.png (the name we used with index-faces in parameter --external-image-id)

## Simple authentication service using python 

```bash
# create python virtual env

# install boto3
pip install boto3
```

Open ipython and create rekognition client
```python
import boto3

# Create recognition client (dont forget to specify region name, it you are using different default region in your aws config)
client = boto3.client('rekognition', region_name='us-east-1')

# Example: get collections
collections = client.list_collections()
collection_ids = collections.get('CollectionIds')

```

Lets create a buch of usefull functions
```python

# Read image from file as a byte array
def read_image(image_name):
    with open(image_name, "rb") as imageFile:
        f = imageFile.read()
        return bytearray(f)

# Search for similar images using aws recognition collection
def search_faces(img_bytes, collection_id):
    image = {
        'Bytes': img_bytes
    }
    # http://boto3.readthedocs.io/en/latest/reference/services/rekognition.html#Rekognition.Client.search_faces_by_image
    response = client.search_faces_by_image(CollectionId=collection_id, Image=image, MaxFaces=5)
    return response

# based on recognition response we try to authenticate person
def authenticate_person(aws_recognition_response, target_similarity = 95):
    authenticated_person = None
    face_matches = aws_recognition_response.get('FaceMatches')
    if len(face_matches) > 0:
        # got some matches
        matched_face_image_id = face_matches[0].get('Face').get('ExternalImageId')
        similarity = face_matches[0].get('Similarity')
        if similarity > target_similarity:
            authenticated_person = matched_face_image_id
        
    return matched_face_image_id 
    
```

Now, we need to get a person picture (for example we can use raspberry camera)
```python
# input image path
img_to_recognize_path = '<image-path-to-recognize>.png'
# recognition image index collection
collection_id = 'friends'
# target similarity must be at least 95%
target_similarity = 95

# image to bytes
img_bytes = read_image(img_to_recognize_path)
response = search_faces(img_bytes, collection_id)
persone_id = authenticate_person(response, target_similarity)
if persone_id:
    print('welcome {}'.format(persone_id))
else:
    print('authentication failed')

```

## Intresting projects using AWS recognition service

[Building face-recognizing doorbell](https://www.oreilly.com/ideas/build-a-talking-face-recognizing-doorbell-for-about-100)
