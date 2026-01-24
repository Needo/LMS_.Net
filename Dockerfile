# Use Node.js for building Angular
FROM node:20-alpine AS angular-build

WORKDIR /app/frontend

# Copy frontend package files
COPY LMSUI/package*.json ./

# Install dependencies
RUN npm ci

# Copy frontend source
COPY LMSUI/ ./

# Build Angular app for production
RUN npm run build

# Use .NET SDK for building backend
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS dotnet-build

WORKDIR /app/backend

# Copy backend project files
COPY LMSBackend/*.csproj ./

# Restore dependencies
RUN dotnet restore

# Copy backend source
COPY LMSBackend/ ./

# Build backend
RUN dotnet publish -c Release -o /app/publish

# Final runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0

WORKDIR /app

# Install SQL Server tools
RUN apt-get update && \
    apt-get install -y curl gnupg2 && \
    curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl https://packages.microsoft.com/config/debian/11/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y msodbcsql18 mssql-tools18 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy published backend
COPY --from=dotnet-build /app/publish .

# Copy built Angular app to wwwroot
COPY --from=angular-build /app/frontend/dist/lmsui/browser ./wwwroot

# Create directories for data persistence
RUN mkdir -p /app/data /app/courses

# Expose port
EXPOSE 5000

# Set environment variables
ENV ASPNETCORE_URLS=http://+:5000
ENV ASPNETCORE_ENVIRONMENT=Production

# Run the application
ENTRYPOINT ["dotnet", "LMSBackend.dll"]
