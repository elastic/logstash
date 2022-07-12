FROM golang:1
RUN go env -w GO111MODULE=off && (for i in 0 1 2 3 4 5; do sleep "$i"; go get gopkg.in/yaml.v2 && break; done)
WORKDIR /usr/local/src/env2yaml
CMD ["go", "build"]
