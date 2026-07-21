FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY ["DogShelter.Worker/DogShelter.Worker.csproj", "DogShelter.Worker/"]
COPY ["DogShelter.Services/DogShelter.Services.csproj", "DogShelter.Services/"]
COPY ["DogShelter.Model/DogShelter.Model.csproj", "DogShelter.Model/"]
RUN dotnet restore "DogShelter.Worker/DogShelter.Worker.csproj"

COPY . .
WORKDIR "/src/DogShelter.Worker"
RUN dotnet build "DogShelter.Worker.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "DogShelter.Worker.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "DogShelter.Worker.dll"]
