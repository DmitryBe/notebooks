
<!-- TOC -->

- [Streams](#streams)
    - [Reading entire InputStream into byte array](#reading-entire-inputstream-into-byte-array)

<!-- /TOC -->

## Streams

### Reading entire InputStream into byte array

```java
InputStream is;
byte[] bytes = IOUtils.toByteArray(is);
```

Internally this creates a ByteArrayOutputStream and copies the bytes to the output, then calls toByteArray(). It handles large files by copying the bytes in blocks of 4KiB.

```java
InputStream is = ...
ByteArrayOutputStream buffer = new ByteArrayOutputStream();

int nRead;
byte[] data = new byte[16384];

while ((nRead = is.read(data, 0, data.length)) != -1) {
  buffer.write(data, 0, nRead);
}

buffer.flush();

return buffer.toByteArray();
```

[More information from stackoverflow](https://stackoverflow.com/questions/1264709/convert-inputstream-to-byte-array-in-java)
