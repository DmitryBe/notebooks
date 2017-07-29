# Spark structural streaming 

[Latest programming guide] (https://spark.apache.org/docs/latest/structured-streaming-programming-guide.html#managing-streaming-queries)

[Book](https://jaceklaskowski.gitbooks.io/spark-structured-streaming/spark-sql-streaming-KeyValueGroupedDataset.html#flatMapGroupsWithState)

## Reading data from socket

Build spark session
```scala
import org.apache.spark.sql.functions._
import org.apache.spark.sql.SparkSession

val spark = SparkSession
  .builder
  .master("local[*]") // use all available cores
  .appName("test-all")
  .config("spark.sql.streaming.checkpointLocation", "./checkpoints") // checkpoint path (must be s3|hdfs)
  .getOrCreate()
  
import spark.implicits._
```

Stream data from socket
```scala
val lines: Dataset[String] = spark.readStream
      .format("socket")
      .option("host", host)
      .option("port", port)
      .load()
      .as[String]
//lines is a boundless Dataset[String

val words = lines.flatMap(_.split(" "))

// Generate running word count
val wordCounts = words.groupBy("value").count()

// Start running the query that prints the running counts to the console
val query = wordCounts.writeStream
    .outputMode("complete")
    .format("console")
    .start()

query.awaitTermination()
```

