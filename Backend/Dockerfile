# Build Stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy csproj and restore
COPY ["Backend.csproj", "./"]
RUN dotnet restore "./Backend.csproj"

# Copy everything else and build
COPY . .
RUN dotnet build "Backend.csproj" -c Release -o /app/build

# Publish Stage
FROM build AS publish
RUN dotnet publish "Backend.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Final Runtime Stage
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Render specifically looks for PORT environment variable
# We set it to 8080 by default, but Render will override this
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

# For QuestPDF (PDF Generation) on Linux
RUN apt-get update && apt-get install -y libgdiplus libx11-dev && apt-get clean && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["dotnet", "Backend.dll"]
