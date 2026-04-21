using FluentAssertions;
using NSubstitute;
using Sheetstorm.PdfLabeling.Abstractions;
using Sheetstorm.PdfLabeling.Services;
using System.Net;
using System.Text;
using System.Text.Json;
using Xunit;

namespace Sheetstorm.PdfLabeling.Tests.Services;

public class GitHubModelsTitleRecognizerTests
{
    private readonly ITitleRecognizerTokenProvider _mockTokenProvider;
    private readonly TestHttpMessageHandler _mockHandler;
    private readonly HttpClient _httpClient;

    public GitHubModelsTitleRecognizerTests()
    {
        _mockTokenProvider = Substitute.For<ITitleRecognizerTokenProvider>();
        _mockTokenProvider.GetTokenAsync(Arg.Any<CancellationToken>())
            .Returns(new ValueTask<string>("ghp_test"));
        
        _mockHandler = new TestHttpMessageHandler();
        _httpClient = new HttpClient(_mockHandler)
        {
            BaseAddress = new Uri("https://models.github.ai/")
        };
    }

    [Fact]
    public async Task RecognizeTitleAsync_ValidJsonResponse_ReturnsParsed()
    {
        // Arrange
        var responseJson = """
        {
            "choices": [{
                "message": {
                    "content": "{\"title\":\"Radetzky Marsch\",\"confidence\":0.95,\"reasoning\":\"Large title at top\"}"
                }
            }]
        }
        """;
        _mockHandler.SetResponse(HttpStatusCode.OK, responseJson);
        
        var sut = new GitHubModelsTitleRecognizer(_httpClient, _mockTokenProvider, retryDelays: []);
        var pngBytes = new byte[] { 0x89, 0x50, 0x4E, 0x47 }; // PNG header

        // Act
        var result = await sut.RecognizeTitleAsync(pngBytes, CancellationToken.None);

        // Assert
        result.Title.Should().Be("Radetzky Marsch");
        result.Confidence.Should().BeApproximately(0.95, 0.001);
        result.Reasoning.Should().Be("Large title at top");
    }

    [Fact]
    public async Task RecognizeTitleAsync_SendsBearerToken_FromProvider()
    {
        // Arrange
        var responseJson = """
        {
            "choices": [{
                "message": {
                    "content": "{\"title\":\"Test\",\"confidence\":0.9,\"reasoning\":\"Test\"}"
                }
            }]
        }
        """;
        _mockHandler.SetResponse(HttpStatusCode.OK, responseJson);
        
        var sut = new GitHubModelsTitleRecognizer(_httpClient, _mockTokenProvider, retryDelays: []);
        var pngBytes = new byte[] { 0x89, 0x50, 0x4E, 0x47 };

        // Act
        await sut.RecognizeTitleAsync(pngBytes, CancellationToken.None);

        // Assert
        _mockHandler.LastRequest.Should().NotBeNull();
        _mockHandler.LastRequest!.Headers.Authorization.Should().NotBeNull();
        _mockHandler.LastRequest.Headers.Authorization!.Scheme.Should().Be("Bearer");
        _mockHandler.LastRequest.Headers.Authorization.Parameter.Should().Be("ghp_test");
        
        await _mockTokenProvider.Received(1).GetTokenAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task RecognizeTitleAsync_SendsPngAsBase64DataUri()
    {
        // Arrange
        var responseJson = """
        {
            "choices": [{
                "message": {
                    "content": "{\"title\":\"Test\",\"confidence\":0.9,\"reasoning\":\"Test\"}"
                }
            }]
        }
        """;
        _mockHandler.SetResponse(HttpStatusCode.OK, responseJson);
        
        var sut = new GitHubModelsTitleRecognizer(_httpClient, _mockTokenProvider, retryDelays: []);
        var pngBytes = new byte[] { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A };

        // Act
        await sut.RecognizeTitleAsync(pngBytes, CancellationToken.None);

        // Assert
        _mockHandler.LastRequestBody.Should().NotBeNullOrEmpty();
        var requestBody = JsonDocument.Parse(_mockHandler.LastRequestBody!);
        var messages = requestBody.RootElement.GetProperty("messages");
        
        var userMessage = messages.EnumerateArray().Last();
        var content = userMessage.GetProperty("content");
        
        var imageUrlEntry = content.EnumerateArray()
            .FirstOrDefault(c => c.GetProperty("type").GetString() == "image_url");
        
        imageUrlEntry.ValueKind.Should().NotBe(JsonValueKind.Undefined);
        var dataUri = imageUrlEntry.GetProperty("image_url").GetProperty("url").GetString();
        
        dataUri.Should().StartWith("data:image/png;base64,");
        var base64Part = dataUri!.Substring("data:image/png;base64,".Length);
        var decodedBytes = Convert.FromBase64String(base64Part);
        decodedBytes.Should().Equal(pngBytes);
    }

    [Fact]
    public async Task RecognizeTitleAsync_SendsCorrectEndpointAndModel()
    {
        // Arrange
        var responseJson = """
        {
            "choices": [{
                "message": {
                    "content": "{\"title\":\"Test\",\"confidence\":0.9,\"reasoning\":\"Test\"}"
                }
            }]
        }
        """;
        _mockHandler.SetResponse(HttpStatusCode.OK, responseJson);
        
        var sut = new GitHubModelsTitleRecognizer(_httpClient, _mockTokenProvider, retryDelays: []);
        var pngBytes = new byte[] { 0x89, 0x50, 0x4E, 0x47 };

        // Act
        await sut.RecognizeTitleAsync(pngBytes, CancellationToken.None);

        // Assert
        _mockHandler.LastRequest.Should().NotBeNull();
        _mockHandler.LastRequest!.RequestUri.Should().NotBeNull();
        _mockHandler.LastRequest.RequestUri!.AbsolutePath.Should().Be("/inference/chat/completions");
        
        _mockHandler.LastRequestBody.Should().NotBeNullOrEmpty();
        var requestBody = JsonDocument.Parse(_mockHandler.LastRequestBody!);
        requestBody.RootElement.GetProperty("model").GetString().Should().Be("openai/gpt-4o");
    }

    [Fact]
    public async Task RecognizeTitleAsync_MalformedInnerJson_ReturnsZeroConfidence()
    {
        // Arrange
        var responseJson = """
        {
            "choices": [{
                "message": {
                    "content": "not json at all"
                }
            }]
        }
        """;
        _mockHandler.SetResponse(HttpStatusCode.OK, responseJson);
        
        var sut = new GitHubModelsTitleRecognizer(_httpClient, _mockTokenProvider, retryDelays: []);
        var pngBytes = new byte[] { 0x89, 0x50, 0x4E, 0x47 };

        // Act
        var result = await sut.RecognizeTitleAsync(pngBytes, CancellationToken.None);

        // Assert
        result.Confidence.Should().Be(0.0);
        result.Title.Should().Be("");
    }

    [Fact]
    public async Task RecognizeTitleAsync_HttpError401_Throws()
    {
        // Arrange
        _mockHandler.SetResponse(HttpStatusCode.Unauthorized, "Unauthorized");
        
        var sut = new GitHubModelsTitleRecognizer(_httpClient, _mockTokenProvider, retryDelays: []);
        var pngBytes = new byte[] { 0x89, 0x50, 0x4E, 0x47 };

        // Act & Assert
        var act = async () => await sut.RecognizeTitleAsync(pngBytes, CancellationToken.None);
        await act.Should().ThrowAsync<HttpRequestException>();
    }

    [Fact]
    public async Task RecognizeTitleAsync_Http429_RetriesThenSucceeds()
    {
        // Arrange
        var successResponse = """
        {
            "choices": [{
                "message": {
                    "content": "{\"title\":\"Success\",\"confidence\":0.9,\"reasoning\":\"After retries\"}"
                }
            }]
        }
        """;
        _mockHandler.SetResponses(
            (HttpStatusCode.TooManyRequests, "Rate limited"),
            (HttpStatusCode.TooManyRequests, "Rate limited"),
            (HttpStatusCode.OK, successResponse)
        );
        
        var sut = new GitHubModelsTitleRecognizer(_httpClient, _mockTokenProvider, 
            retryDelays: [TimeSpan.Zero, TimeSpan.Zero, TimeSpan.Zero]);
        var pngBytes = new byte[] { 0x89, 0x50, 0x4E, 0x47 };

        // Act
        var result = await sut.RecognizeTitleAsync(pngBytes, CancellationToken.None);

        // Assert
        result.Title.Should().Be("Success");
        _mockHandler.CallCount.Should().Be(3);
    }

    [Fact]
    public async Task RecognizeTitleAsync_Http500_RetriesThenFails()
    {
        // Arrange
        _mockHandler.SetResponse(HttpStatusCode.InternalServerError, "Server Error");
        
        var sut = new GitHubModelsTitleRecognizer(_httpClient, _mockTokenProvider, 
            retryDelays: [TimeSpan.Zero, TimeSpan.Zero, TimeSpan.Zero]);
        var pngBytes = new byte[] { 0x89, 0x50, 0x4E, 0x47 };

        // Act & Assert
        var act = async () => await sut.RecognizeTitleAsync(pngBytes, CancellationToken.None);
        await act.Should().ThrowAsync<HttpRequestException>();
        
        _mockHandler.CallCount.Should().Be(4); // 1 initial + 3 retries
    }

    [Fact]
    public async Task RecognizeTitleAsync_Cancellation_Propagates()
    {
        // Arrange
        var responseJson = """
        {
            "choices": [{
                "message": {
                    "content": "{\"title\":\"Test\",\"confidence\":0.9,\"reasoning\":\"Test\"}"
                }
            }]
        }
        """;
        _mockHandler.SetResponse(HttpStatusCode.OK, responseJson);
        
        var sut = new GitHubModelsTitleRecognizer(_httpClient, _mockTokenProvider, retryDelays: []);
        var pngBytes = new byte[] { 0x89, 0x50, 0x4E, 0x47 };
        var cts = new CancellationTokenSource();
        cts.Cancel();

        // Act & Assert
        var act = async () => await sut.RecognizeTitleAsync(pngBytes, cts.Token);
        await act.Should().ThrowAsync<OperationCanceledException>();
    }

    [Fact]
    public async Task RecognizeTitleAsync_EmptyPng_Throws()
    {
        // Arrange
        var sut = new GitHubModelsTitleRecognizer(_httpClient, _mockTokenProvider, retryDelays: []);
        var emptyBytes = Array.Empty<byte>();

        // Act & Assert
        var act = async () => await sut.RecognizeTitleAsync(emptyBytes, CancellationToken.None);
        await act.Should().ThrowAsync<ArgumentException>();
    }
}

internal sealed class TestHttpMessageHandler : HttpMessageHandler
{
    private readonly Queue<(HttpStatusCode StatusCode, string Content)> _responses = new();
    private (HttpStatusCode StatusCode, string Content)? _defaultResponse;
    
    public HttpRequestMessage? LastRequest { get; private set; }
    public string? LastRequestBody { get; private set; }
    public int CallCount { get; private set; }

    public void SetResponse(HttpStatusCode statusCode, string content)
    {
        _defaultResponse = (statusCode, content);
    }

    public void SetResponses(params (HttpStatusCode StatusCode, string Content)[] responses)
    {
        _responses.Clear();
        foreach (var response in responses)
        {
            _responses.Enqueue(response);
        }
    }

    protected override async Task<HttpResponseMessage> SendAsync(
        HttpRequestMessage request, CancellationToken cancellationToken)
    {
        CallCount++;
        LastRequest = request;
        
        if (request.Content != null)
        {
            LastRequestBody = await request.Content.ReadAsStringAsync(cancellationToken);
        }

        var response = _responses.Count > 0 
            ? _responses.Dequeue() 
            : _defaultResponse ?? throw new InvalidOperationException("No response configured");

        return new HttpResponseMessage(response.StatusCode)
        {
            Content = new StringContent(response.Content, Encoding.UTF8, "application/json")
        };
    }
}
