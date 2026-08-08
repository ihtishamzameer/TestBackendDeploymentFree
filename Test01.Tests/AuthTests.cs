using Microsoft.AspNetCore.Mvc.Testing;

namespace Test01.Tests
{
    public class AuthTests : IClassFixture<WebApplicationFactory<Program>>
    {
        private readonly HttpClient _client;

        public AuthTests(WebApplicationFactory<Program> factory)
        {
            _client = factory.CreateClient();
        }

        [Fact]
        public async Task Health_ShouldReturn200()
        {
            // Act
            var response = await _client.GetAsync("/health");

            // Assert
            Assert.Equal(
                System.Net.HttpStatusCode.OK,
                response.StatusCode
            );
        }
    }
}