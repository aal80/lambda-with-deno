clean:
	@echo :clean
	rm -rf build

# Deno layer
build_deno_layer: 
	@echo :build_deno_layer
	rm -rf build/deno-layer
	mkdir -p build/deno-layer/bin
	cp deno/deno-1.22.0-linux build/deno-layer/bin/deno
	chmod 755 build/deno-layer/bin/deno
	cd build/deno-layer; \
		zip -r ../deno-layer.zip .

deploy_deno_layer: build_deno_layer
	@echo :deploy_deno_layer
	aws lambda publish-layer-version \
    	--layer-name deno-layer \
    	--compatible-runtimes provided.al2 \
    	--compatible-architectures x86_64 \
    	--zip-file fileb://build/deno-layer.zip

# Runtimes
build_runtime_layer:  
	@echo :build_runtime_layer
	rm -f runtime-layer.zip
	rm -rf build/runtime-layer
	cd runtime1; \
		GOOS=linux go build \
			-tags lambda.norpc \
			-o ./../build/runtime-layer/bootstrap \
			bootstrap.go
	cp runtime1/bootstrap.sh build/runtime-layer
	cp runtime1/runtime.js build/runtime-layer
	cp runtime1/function.bundle.js build/runtime-layer
	
	cd build/runtime-layer; \
		DENO_DIR=.deno_dir deno cache runtime.js; 

	cd build/runtime-layer; \
		chmod 755 bootstrap; \
		chmod 755 bootstrap.sh; \
		zip -r ../runtime-layer.zip .deno_dir bootstrap bootstrap.sh runtime.js function.bundle.js

deploy_runtime_layer: 
	@echo :deploy_runtime_layer
	aws lambda publish-layer-version \
    	--layer-name runtime-layer \
    	--compatible-runtimes provided.al2 \
    	--compatible-architectures x86_64 \
    	--zip-file fileb://build/runtime-layer.zip

# Function
build_function:
	@echo :build_function
	rm -f function.zip
	rm -rf build/function	
	mkdir -p build/function
	cp function/function.ts build/function
	cd build/function; \
		DENO_DIR=.deno_dir deno cache function.ts; \
		DENO_DIR=.deno_dir deno bundle function.ts function.bundle.js
	cd build/function; \
		zip -r ../function.zip .deno_dir function.bundle.js

# Update these values after deploying Deno and Runtime layers
FUNCTION_ROLE_ARN=arn:aws:iam::281024298475:role/lambda-role
DENO_LAYER_ARN=arn:aws:lambda:us-east-1:281024298475:layer:deno-layer:9
RUNTIME_LAYER_ARN=arn:aws:lambda:us-east-1:281024298475:layer:runtime-layer:7
FUNCTION_NAME=custom-runtime-with-deno-function

create_function: build_function
	@echo create_function
	aws lambda create-function \
		--function-name $(FUNCTION_NAME) \
		--runtime provided.al2 \
		--handler hello.handler \
		--timeout 5 \
		--role $(FUNCTION_ROLE_ARN) \
		--memory-size 256 \
		--layers $(DENO_LAYER_ARN) $(RUNTIME_LAYER_ARN) \
		--zip-file fileb://build/function.zip

delete_function: 
	@echo delete_function
	aws lambda delete-function \
		--function-name $(FUNCTION_NAME) \

update-function-configuration: build_function
	@echo update_function_after_updating_layers
	aws lambda update-function-configuration \
		--function-name $(FUNCTION_NAME) \
		--layers $(DENO_LAYER_ARN) $(RUNTIME_LAYER_ARN) 

update-function-code: build_function
	@echo :redeploy_function
	aws lambda update-function-code \
		--function-name $(FUNCTION_NAME) \
		--zip-file fileb://build/function.zip
