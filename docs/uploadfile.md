# Uploaded Files

`getUploadFile` accepts the name(from the html-input name attribute) of the file and returns an UploadFile Object. The UploadFile Object contains the filename and contents of the file. For this example, the name is "userfile". 

```html
<form action="upload" method="post" enctype="multipart/form-data">
  <input type="file" name="userfile">
  <input type="submit" value="Submit">
</form>
```

`getUploadFile` only works when using form parameters and HttpPost method. `Context` provides a helper function to `save` the uploadFile to disks. If you don't specify the name of the file, it will use the original filename from the client.

```nim
proc upload(ctx: Context) {.async.} =
  if ctx.request.reqMethod == HttpGet:
    await ctx.staticFileResponse("tests/local/uploadFile/upload.html", "")
  elif ctx.request.reqMethod == HttpPost:
    let file = ctx.getUploadFile("userfile")
    file.save("tests/assets/temp") #here the file would be saved with the original filename from the client.
    file.save("tests/assets/temp", "set.txt") #here we give the file a custom name of "set.txt"
    resp fmt"<html><h1>{file.filename}</h1><p>{file.body}</p></html>"
```

The full [example](https://github.com/planety/prologue/blob/devel/tests/local/uploadFile/local_uploadFile_test.nim)
