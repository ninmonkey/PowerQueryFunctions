let
    // Define metadata for the function, describing its purpose and usage.
    metaDocumentation = type function (
        apiKey as (type text meta [
            Documentation.FieldCaption = "Open API Key",
            Documentation.SampleValues = {"sk-"},
            Formatting.IsMultiLine = false,
            Formatting.IsCode = false
        ]),
        model as (type text meta [
            Documentation.FieldCaption = "GPT Model",
            Documentation.AllowedValues = {"gpt-3.5-turbo"},
            Formatting.IsMultiLine = false,
            Formatting.IsCode = false
        ]),
        prompt as (type text meta [
            Documentation.FieldCaption = "MGPT Prompt",
            Documentation.SampleValues = {"Please show me how to create a Date Table"},
            Formatting.IsMultiLine = true,
            Formatting.IsCode = true
        ])
    ) as text meta [
        Documentation.Name = "MCopilot",
        Documentation.LongDescription = "
            <p><b>MCopilot</b></p>
            <li><b>Creator: </b>Oscar Martinez.</li>
            <li><b>LinkedIn:</b> https://www.linkedin.com/in/oscarmartinezv/.</li>
            <li><b>Web: </b>bibb.pro</li>

            <p>This function, interacts with the OpenAI API to provide responses based on given prompts. It serves as a tool for generating meaningful explanations and full code related to Power Query.</p>
            <p>The function takes three parameters:</p>
            <ul>
                <li><b>apiKey:</b> This is the Open API Key required for authentication.</li>
                <li><b>model:</b> This is the GPT chosen model.</li>
                <li><b>prompt:</b> This is the prompt provided to the function, requesting information or code related to Power Query.</li>
            </ul>
            <p>The function,  constructs a request to the OpenAI API endpoint <code>https://api.openai.com/v1/chat/completions</code>.</p>
            <p>The request body includes a system message indicating the role of the responder, as well as the user's prompt. The API key is included in the request headers for authentication.</p>
            <p>Upon receiving the response from the API, the function extracts the content of the response message and returns it as the output.</p>

            <p>See more:</p>
            <ul>
                <li><b>Models:</b> <code>https://platform.openai.com/docs/models/overview</code></li>
            </ul>
        "

    ],

    // Define the main function to interact with the OpenAI API.
    MGPT = (apiKey as text, model as text, prompt as text) as text => let
        /*
        To make Web.Contents more likey to be refreshable, here's two things that can help

        1. The first parameter for `Web.Contents` should be as short as possible.
            Anything after the domain or the first `/` should be moved to `RelativePath`
            and `Query`

        2. If you replace the `baseUrl` variable with a `Report Parameter` -- I've heard it allows you to refresh some
            datasources that would normally error. Like SQL Server/instance names

        see also: Wait-Retry pattern: <https://learn.microsoft.com/en-us/power-query/wait-retry>
        */
        returnExtraContext = true,
        baseUrl = "https://api.openai.com",
        requestOptions = [
            RelativePath = "/v1/chat/completions",
            Headers      = Headers,
            Content      = Json.FromValue( promptsPayload, TextEncoding.Utf8 ),
            // Timeout = #duration(0, 0, 0, 30),
            // IsRetry = ,
            ManualStatusHandling = { 400, 404, 408, 429, 500, 503, 504, 509 }
        ],
        Headers = [
            #"Content-Type" = "application/json",
            Authorization = "Bearer " & apiKey
        ],
        promptsPayload = [
            model = model,
            messages = {
                [   role = "system",
                    content = "You are a Power Query expert, your role is to respond with meaningful explanations and full code" ],

                [   role = "user",
                    content = prompt ]
            }
        ],
        /*
        tip: If you split a `Json.Document( Web.Contents( ... ))` call into two steps, you get access to to additional
        information about the request. HTTP status codes, response headers, the full request URL, and more.

        And it lets you handle APIs that switch content types.
        Some APIs return data as JSON, but switch to HTML when reporting errors.

        `RawText` is useful when debugging because it lets you read any response as text.
        For example if it returns `xml`. The `Json` field will have an exception
        But you can view the `RawText` of that `xml` response as plain text

        It also lets you support an API call that switches between json and html when it responds.
        // some web APIs return errors as html, rather than json
        // response is type: `binary`
        // keeping a reference fcreate a referece to the raw web requestresponse is the type `binary`
        // it's a reference to the raw bytes returned from the web request. It'sgives you a extra  a reference to the raw bytes returned from the web request.
        // response is the raw bytes from the request, type is: `binary`

        */
        // Source = Json.Document(Web.Contents(baseUrl, [
        //     Headers = Headers,
        //     Content = Text.ToBinary(body)
        // ])),
        response = Web.Contents( baseUrl, requestOptions ),
        Response = [
            Bytes        = response,
            Meta         = Value.Metadata( Bytes ),
            Json         = Json.Document( Bytes ),
            IsJson       = not ( try Json )[HasError],
            RawText      = Text.FromBinary( response, TextEncoding.Utf8 ),
            SizeBytes    = Binary.Length( Bytes ),
            Completion   = Json[choices]{0}[message][content], // you could use `??` for a 'fallback'
            // drill into [Meta] for more info. include a few properties at the top level
            StatusCode   = Meta[Response.Status],
            RequestUrl   = Meta[Content.Uri](),
            Content.Type = Meta[Content.Type]
        ],
        SourceBasic = Response[Json],
        SourceWithContext = Response


        // API key and headers configuration. Remember to replace {Your API Key} with your actual API key.
        // Execute the web request and parse the JSON response.
        // Source = Json.Document(Web.Contents(baseUrl, [
        //     Headers = Headers,
        //     Content = Text.ToBinary(body)
        // ])),
        // Response = Source[choices]{0}[message][content]
    in

        if returnExtraContext then SourceWithContext else SourceBasic
in
    // Apply the function metadata to the MGPT function.
    Value.ReplaceType(MGPT, metaDocumentation)
