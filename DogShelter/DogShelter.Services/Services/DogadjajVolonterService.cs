using AutoMapper;
using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Database;
using DogShelter.Services.Exceptions;
using DogShelter.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace DogShelter.Services.Services;

public class DogadjajVolonterService : IDogadjajVolonterService
{
    private readonly DogShelterContext _context;
    private readonly IMapper _mapper;
    private readonly IEmailSender _emailSender;
    private readonly ILogger<DogadjajVolonterService> _logger;

    public DogadjajVolonterService(DogShelterContext context, IMapper mapper, IEmailSender emailSender, ILogger<DogadjajVolonterService> logger)
    {
        _context = context;
        _mapper = mapper;
        _emailSender = emailSender;
        _logger = logger;
    }

    private IQueryable<Database.DogadjajVolonter> BaseQuery() =>
        _context.DogadjajVolonters
            .Include(dv => dv.Dogadjaj)
            .Include(dv => dv.Volonter).ThenInclude(v => v.Korisnik)
            .AsNoTracking();

    public async Task<PagedResult<Model.DogadjajVolonter>> Get(DogadjajVolonterSearchRequest search, int callerKorisnikId, bool isAdmin)
    {
        var query = BaseQuery();

        if (search.DogadjajId.HasValue)
            query = query.Where(dv => dv.DogadjajId == search.DogadjajId.Value);

        if (isAdmin)
        {
            if (search.VolonterId.HasValue)
                query = query.Where(dv => dv.VolonterId == search.VolonterId.Value);
        }
        else
        {
            var volonter = await _context.Volonters.FirstOrDefaultAsync(v => v.KorisnikId == callerKorisnikId)
                ?? throw new BusinessException("Nemate evidentiran volonterski profil.");
            query = query.Where(dv => dv.VolonterId == volonter.VolonterId);
        }

        query = query.OrderBy(dv => dv.Dogadjaj.Datum);

        return await PagedQueryHelper.ToPagedResultAsync<Database.DogadjajVolonter, Model.DogadjajVolonter>(query, search, _mapper);
    }

    public async Task<Model.DogadjajVolonter> Zaduzi(DogadjajVolonterInsertRequest request)
    {
        var dogadjaj = await _context.Dogadjajs.FindAsync(request.DogadjajId)
            ?? throw new ValidationException("Odabrani događaj ne postoji.", nameof(request.DogadjajId), "Događaj ne postoji.");

        if (!dogadjaj.Aktivan)
            throw new BusinessException("Nije moguće zadužiti volontera za otkazan događaj.");

        var volonter = await _context.Volonters.Include(v => v.Korisnik).FirstOrDefaultAsync(v => v.VolonterId == request.VolonterId)
            ?? throw new ValidationException("Odabrani volonter ne postoji.", nameof(request.VolonterId), "Volonter ne postoji.");

        if (!volonter.Aktivan)
            throw new BusinessException("Nije moguće zadužiti neaktivnog volontera.");

        if (await _context.DogadjajVolonters.AnyAsync(dv => dv.DogadjajId == request.DogadjajId && dv.VolonterId == request.VolonterId))
            throw new BusinessException("Volonter je već zadužen za ovaj događaj.");

        var entity = new Database.DogadjajVolonter
        {
            DogadjajId = request.DogadjajId,
            VolonterId = request.VolonterId
        };

        _context.DogadjajVolonters.Add(entity);
        await _context.SaveChangesAsync();

        await SendZaduzenjeEmailAsync(volonter, dogadjaj);

        var saved = await BaseQuery().FirstAsync(dv => dv.DogadjajVolonterId == entity.DogadjajVolonterId);
        return _mapper.Map<Model.DogadjajVolonter>(saved);
    }

    public async Task<bool> Ukloni(int id)
    {
        var entity = await _context.DogadjajVolonters.FindAsync(id)
            ?? throw new NotFoundException($"Zaduženje s ID {id} nije pronađeno.");

        _context.DogadjajVolonters.Remove(entity);
        await _context.SaveChangesAsync();

        return true;
    }

    private async Task SendZaduzenjeEmailAsync(Database.Volonter volonter, Database.Dogadjaj dogadjaj)
    {
        try
        {
            var subject = $"Zaduženje za događaj: {dogadjaj.Naziv}";
            var body = $"Poštovani/a {volonter.Korisnik.Ime},\n\n" +
                       $"Zaduženi ste za događaj \"{dogadjaj.Naziv}\" koji se održava {dogadjaj.Datum:dd.MM.yyyy HH:mm} na lokaciji {dogadjaj.Lokacija}.\n\n" +
                       "Hvala na Vašem volonterskom angažmanu!\nAzil za pse Bugojno";

            await _emailSender.SendAsync(volonter.Korisnik.Email, subject, body);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send zaduženje email to {Email}.", volonter.Korisnik.Email);
        }
    }
}
