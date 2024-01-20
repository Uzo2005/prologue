# Copyright 2020 Zeshen Xing
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import std/[strtabs, strutils, strformat, parseutils, tables]
from std/uri import decodeQuery

import ./httpcore/httplogue
from ./types import FormPart, initFormPart, add
import ./request


func parseFormPart*(body, contentType: string): FormPart =
  ## Parses form part of the body of the request.
  let
    sep = contentType[contentType.rfind("boundary") + 9 .. ^1]
    startSep = fmt"--{sep}"
    endSep = fmt"--{sep}--"
    startPos = find(body, startSep) + startSep.len + 2  # 2 because of protocol newline after boundary
    endPos = rfind(body, endSep)
    formData = body[startPos ..< endPos]
    formDataSeq = formData.split(startSep & "\c\L")

  result = initFormPart()
  for data in formDataSeq:
    var newFormData: tuple[params: StringTableRef, body: string] = (newStringTable(mode = modeCaseSensitive), "")

    if data.len == 0:
      continue
    
    var
      pos = 0
      head, tail: string
      name: string
      times = 0
      tok = ""
      formKey, formValue: string

    pos += parseUntil(data, head, "\c\L\c\L")
    inc(pos, 4)
    tail = data[pos ..< ^2] # 2 because of protocol newline after content disposition body

    

    if not head.startsWith("Content-Disposition"):
      break
    
    for line in head.splitLines:
      let header = line.parseHeader
      if header.key != "Content-Disposition":
        newFormData.params[header.key] = header.value[0]
        # result.data[name].params[header.key] = header.value[0]
        continue
      pos = 0
      let
        content = header.value[0]
        length = content.len
      pos += parseUntil(content, tok, ';', pos)

      while pos < length:
        pos += skipWhile(content, {';', ' '}, pos)
        pos += parseUntil(content, formKey, '=', pos)
        pos += skipWhile(content, {'=', '\"'}, pos)
        pos += parseUntil(content, formValue, '\"', pos)
        pos += skipWhile(content, {'\"'}, pos)

        case formKey
        of "name":
          name = move(formValue)
          if not(result.data.hasKey(name)):
            result.data[name] = newSeq[tuple[params: StringTableRef, body: string]]()
          # result.data[name] = newSeqWith(1, (newStringTable(mode = modeCaseSensitive), ""))
          # result.data[name] = (newStringTable(mode = modeCaseSensitive), "")
        of "filename":
          newFormData.params["filename"] = move(formValue)
          # result.data[name].params["filename"] = move(formValue)
        of "filename*": #(uzo2005)is this really needed when parsing formdata?
          newFormData.params["filenameStar"] = move(formValue)
          # result.data[name].params["filenameStar"] = move(formValue)
        else:
          discard
        inc(times)
        if times >= 3:
          break

    newFormData.body = tail
    result.data[name].add(newFormData)
  
      

func parseFormParams*(request: var Request, contentType: string) =
  ## Parses get or post or query parameters.
  if "form-urlencoded" in contentType:
    request.formParams = initFormPart()
    if request.reqMethod == HttpPost:
      for (key, value) in decodeQuery(request.body):
        # formParams and postParams for secret event
        request.formParams.add(key, value)
        request.postParams[key] = value
  elif "multipart/form-data" in contentType and "boundary" in contentType:
    request.formParams = parseFormPart(request.body, contentType)

  # /student?name=simon&age=sixteen
  # query -> name=simon&age=sixteen

  for (key, value) in decodeQuery(request.query):
    request.queryParams[key] = value



  



