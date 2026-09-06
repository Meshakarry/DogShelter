using DogShelter.Services.Exceptions;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;

namespace DogShelter.Services.Services;

public class FileUploadService : IFileUploadService
{
    private readonly IWebHostEnvironment _env;

    private static readonly string[] AllowedExtensions = [".jpg", ".jpeg", ".png", ".webp"];

    private static readonly string[] AllowedContentTypes =
        ["image/jpeg", "image/pjpeg", "image/png", "image/webp"];

    // Magic byte signatures: (offset, bytes)
    private static readonly (int Offset, byte[] Signature, string Type)[] Signatures =
    [
        (0, [0xFF, 0xD8, 0xFF], "JPEG"),
        (0, [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A], "PNG"),
        (0, [0x52, 0x49, 0x46, 0x46], "WEBP_RIFF"), // followed by WebP at offset 8
    ];

    public FileUploadService(IWebHostEnvironment env)
    {
        _env = env;
    }

    public async Task<string> SaveImageAsync(IFormFile file, string subfolder)
    {
        var (ext, fileName) = await ValidateAndNameAsync(file);

        var folder = Path.Combine(_env.WebRootPath, "images", subfolder);
        Directory.CreateDirectory(folder);

        var fullPath = Path.Combine(folder, fileName);
        await using var stream = new FileStream(fullPath, FileMode.Create);
        await file.CopyToAsync(stream);

        return $"/images/{subfolder}/{fileName}";
    }

    public void DeleteImage(string? relativePath)
    {
        if (string.IsNullOrWhiteSpace(relativePath)) return;

        // relativePath is like /images/psi/abc.jpg
        var combined = Path.Combine(_env.WebRootPath, relativePath.TrimStart('/').Replace('/', Path.DirectorySeparatorChar));
        var fullPath = ResolveWithinRoot(_env.WebRootPath, combined);
        if (fullPath != null && File.Exists(fullPath))
            File.Delete(fullPath);
    }

    public async Task<string> SavePrivateImageAsync(IFormFile file, string subfolder)
    {
        var (_, fileName) = await ValidateAndNameAsync(file);

        var folder = Path.Combine(_env.ContentRootPath, "PrivateFiles", subfolder);
        Directory.CreateDirectory(folder);

        var fullPath = Path.Combine(folder, fileName);
        await using var stream = new FileStream(fullPath, FileMode.Create);
        await file.CopyToAsync(stream);

        return $"{subfolder}/{fileName}";
    }

    public void DeletePrivateImage(string? relativePath)
    {
        var fullPath = GetPrivateFilePath(relativePath);
        if (fullPath != null)
            File.Delete(fullPath);
    }

    public string? GetPrivateFilePath(string? relativePath)
    {
        if (string.IsNullOrWhiteSpace(relativePath)) return null;

        var root = Path.Combine(_env.ContentRootPath, "PrivateFiles");
        var combined = Path.Combine(root, relativePath.Replace('/', Path.DirectorySeparatorChar));
        var fullPath = ResolveWithinRoot(root, combined);
        return fullPath != null && File.Exists(fullPath) ? fullPath : null;
    }

    // relativePath ultimately comes from a database column (Korisnik.SlikaPutanja) that, while no
    // longer directly client-settable (see RegisterRequest/KorisnikUpdateRequest etc.), is still
    // worth defending in depth here: Path.GetFullPath collapses any "../" segments, and the result
    // is only accepted if it's still inside root - so a crafted or corrupted value can't be used to
    // read or delete a file anywhere else on disk.
    private static string? ResolveWithinRoot(string root, string combinedPath)
    {
        var normalizedRoot = Path.GetFullPath(root + Path.DirectorySeparatorChar);
        var fullPath = Path.GetFullPath(combinedPath);
        return fullPath.StartsWith(normalizedRoot, StringComparison.OrdinalIgnoreCase) ? fullPath : null;
    }

    public string GetContentType(string relativePath) => Path.GetExtension(relativePath).ToLowerInvariant() switch
    {
        ".png" => "image/png",
        ".webp" => "image/webp",
        _ => "image/jpeg",
    };

    private static async Task<(string Extension, string FileName)> ValidateAndNameAsync(IFormFile file)
    {
        if (file == null || file.Length == 0)
            throw new ValidationException("Slika nije priložena ili je prazna.");

        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (!AllowedExtensions.Contains(ext))
            throw new ValidationException($"Dozvoljeni formati: {string.Join(", ", AllowedExtensions)}.");

        // Declared Content-Type is trivially spoofable on its own, same as the extension - it's
        // checked alongside (not instead of) the magic-byte sniff below, as a cheap extra layer.
        if (string.IsNullOrWhiteSpace(file.ContentType) || !AllowedContentTypes.Contains(file.ContentType.ToLowerInvariant()))
            throw new ValidationException("Nevažeći MIME tip datoteke.");

        await ValidateMagicBytesAsync(file);

        return (ext, $"{Guid.NewGuid()}{ext}");
    }

    private static async Task ValidateMagicBytesAsync(IFormFile file)
    {
        var header = new byte[12];
        await using var stream = file.OpenReadStream();
        var read = await stream.ReadAsync(header.AsMemory(0, header.Length));

        if (read < 3)
            throw new ValidationException("Datoteka je previše mala da bi bila validna slika.");

        // JPEG: FF D8 FF
        if (header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF)
            return;

        // PNG: 89 50 4E 47 0D 0A 1A 0A
        if (read >= 8 &&
            header[0] == 0x89 && header[1] == 0x50 && header[2] == 0x4E && header[3] == 0x47 &&
            header[4] == 0x0D && header[5] == 0x0A && header[6] == 0x1A && header[7] == 0x0A)
            return;

        // WebP: RIFF????WEBP
        if (read >= 12 &&
            header[0] == 0x52 && header[1] == 0x49 && header[2] == 0x46 && header[3] == 0x46 &&
            header[8] == 0x57 && header[9] == 0x45 && header[10] == 0x42 && header[11] == 0x50)
            return;

        throw new ValidationException("Sadržaj datoteke ne odgovara dozvoljenoj vrsti slike (JPEG, PNG, WebP).");
    }
}
