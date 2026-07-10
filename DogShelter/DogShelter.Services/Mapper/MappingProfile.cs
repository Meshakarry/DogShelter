using AutoMapper;
using Database = DogShelter.Services.Database;
using Model = DogShelter.Model;

namespace DogShelter.Services.Mapper;

public class MappingProfile : Profile
{
    public MappingProfile()
    {
        CreateMap<Database.Korisnik, Model.Korisnik>()
            .ForMember(d => d.KorisnikUloge, o => o.MapFrom(s => s.KorisnikUlogas));

        CreateMap<Database.Korisnik, Model.Requests.KorisnikInsertRequest>();

        CreateMap<Model.Requests.KorisnikInsertRequest, Database.Korisnik>()
            .ForMember(d => d.SlikaPutanja, o => o.Condition((src, _, _, _) => !string.IsNullOrEmpty(src.SlikaPutanja)))
            .ForMember(d => d.LozinkaHash, o => o.Ignore())
            .ForMember(d => d.LozinkaSalt, o => o.Ignore());

        CreateMap<Model.Requests.KorisnikUpdateRequest, Database.Korisnik>()
            .ForMember(d => d.Aktivan, o => o.MapFrom(s => s.Status ?? false))
            .ForMember(d => d.SlikaPutanja, o => o.Condition((src, _, _, _) => !string.IsNullOrEmpty(src.SlikaPutanja)))
            .ForMember(d => d.LozinkaHash, o => o.Ignore())
            .ForMember(d => d.LozinkaSalt, o => o.Ignore());

        CreateMap<Model.Requests.RegisterRequest, Database.Korisnik>()
            .ForMember(d => d.SlikaPutanja, o => o.Condition((src, _, _, _) => !string.IsNullOrEmpty(src.SlikaPutanja)))
            .ForMember(d => d.LozinkaHash, o => o.Ignore())
            .ForMember(d => d.LozinkaSalt, o => o.Ignore());

        CreateMap<Model.Requests.KorisnikProfileUpdateRequest, Database.Korisnik>()
            .ForMember(d => d.SlikaPutanja, o => o.Condition((src, _, _, _) => !string.IsNullOrEmpty(src.SlikaPutanja)))
            .ForMember(d => d.LozinkaHash, o => o.Ignore())
            .ForMember(d => d.LozinkaSalt, o => o.Ignore());
        CreateMap<Database.Pas, Model.Pas>()
            .ForMember(d => d.RasaNaziv,     o => o.MapFrom(s => s.Rasa != null ? s.Rasa.Naziv : null))
            .ForMember(d => d.StatusNaziv,   o => o.MapFrom(s => s.StatusPsa != null ? s.StatusPsa.Naziv : null))
            .ForMember(d => d.VelicinaNaziv, o => o.MapFrom(s => s.VelicinaPsa != null ? s.VelicinaPsa.Naziv : null))
            .ForMember(d => d.Slike,         o => o.MapFrom(s => s.SlikaPsas));

        CreateMap<Database.Pas, Model.PasListItem>()
            .ForMember(d => d.RasaNaziv,     o => o.MapFrom(s => s.Rasa != null ? s.Rasa.Naziv : null))
            .ForMember(d => d.StatusNaziv,   o => o.MapFrom(s => s.StatusPsa != null ? s.StatusPsa.Naziv : null))
            .ForMember(d => d.VelicinaNaziv, o => o.MapFrom(s => s.VelicinaPsa != null ? s.VelicinaPsa.Naziv : null));

        CreateMap<Model.Requests.PasInsertRequest, Database.Pas>()
            .ForMember(d => d.SlikaNaslovna, o => o.Ignore())
            .ForMember(d => d.Aktivan,       o => o.Ignore());

        CreateMap<Model.Requests.PasUpdateRequest, Database.Pas>()
            .ForMember(d => d.SlikaNaslovna, o => o.Ignore());
        CreateMap<Database.Donacija, Model.Donacija>();
        CreateMap<Database.AktivnostVolontera, Model.AktivnostVolontera>();
        CreateMap<Database.Dogadjaj, Model.Dogadjaj>();
        CreateMap<Database.DogadjajVolonter, Model.DogadjajVolonter>();
        CreateMap<Database.Grad, Model.Grad>();
        CreateMap<Database.KorisnikUloga, Model.KorisnikUloga>();
        CreateMap<Database.Obavijest, Model.Obavijest>();
        CreateMap<Database.Posjeta, Model.Posjeta>();
        CreateMap<Database.PregledPsa, Model.PregledPsa>();
        CreateMap<Database.Rasa, Model.Rasa>();
        CreateMap<Database.SlikaPsa, Model.SlikaPsa>();
        CreateMap<Database.StatusDonacije, Model.StatusDonacije>();
        CreateMap<Database.StatusPosjete, Model.StatusPosjete>();
        CreateMap<Database.StatusPsa, Model.StatusPsa>();
        CreateMap<Database.StatusZahtjeva, Model.StatusZahtjeva>();
        CreateMap<Database.TipAktivnosti, Model.TipAktivnosti>();
        CreateMap<Database.TipDonacije, Model.TipDonacije>();
        CreateMap<Database.Udomljavanje, Model.Udomljavanje>()
            .ForMember(d => d.PasId,           o => o.MapFrom(s => s.ZahtjevZaUdomljavanje.PasId))
            .ForMember(d => d.PasNaziv,        o => o.MapFrom(s => s.ZahtjevZaUdomljavanje.Pas != null ? s.ZahtjevZaUdomljavanje.Pas.Naziv : null))
            .ForMember(d => d.PasSlikaNaslovna, o => o.MapFrom(s => s.ZahtjevZaUdomljavanje.Pas != null ? s.ZahtjevZaUdomljavanje.Pas.SlikaNaslovna : null))
            .ForMember(d => d.KorisnikId,      o => o.MapFrom(s => s.ZahtjevZaUdomljavanje.KorisnikId))
            .ForMember(d => d.KorisnikIme,     o => o.MapFrom(s => s.ZahtjevZaUdomljavanje.Korisnik != null ? s.ZahtjevZaUdomljavanje.Korisnik.Ime : null))
            .ForMember(d => d.KorisnikPrezime, o => o.MapFrom(s => s.ZahtjevZaUdomljavanje.Korisnik != null ? s.ZahtjevZaUdomljavanje.Korisnik.Prezime : null));
        CreateMap<Database.Uloga, Model.Uloga>();
        CreateMap<Database.VelicinaPsa, Model.VelicinaPsa>();
        CreateMap<Database.Volonter, Model.Volonter>();
        CreateMap<Database.ZahtjevZaUdomljavanje, Model.ZahtjevZaUdomljavanje>()
            .ForMember(d => d.KorisnikIme,             o => o.MapFrom(s => s.Korisnik != null ? s.Korisnik.Ime : null))
            .ForMember(d => d.KorisnikPrezime,         o => o.MapFrom(s => s.Korisnik != null ? s.Korisnik.Prezime : null))
            .ForMember(d => d.PasNaziv,                o => o.MapFrom(s => s.Pas != null ? s.Pas.Naziv : null))
            .ForMember(d => d.PasSlikaNaslovna,        o => o.MapFrom(s => s.Pas != null ? s.Pas.SlikaNaslovna : null))
            .ForMember(d => d.StatusZahtjevaNaziv,     o => o.MapFrom(s => s.StatusZahtjeva != null ? s.StatusZahtjeva.Naziv : null))
            .ForMember(d => d.ObradioKorisnikIme,      o => o.MapFrom(s => s.ObradioKorisnik != null ? s.ObradioKorisnik.Ime : null))
            .ForMember(d => d.ObradioKorisnikPrezime,  o => o.MapFrom(s => s.ObradioKorisnik != null ? s.ObradioKorisnik.Prezime : null));

        // Lookup upsert request → database entity mappings
        CreateMap<Model.Requests.GradUpsertRequest, Database.Grad>();
        CreateMap<Model.Requests.RasaUpsertRequest, Database.Rasa>();
        CreateMap<Model.Requests.LookupUpsertRequest, Database.VelicinaPsa>();
        CreateMap<Model.Requests.LookupUpsertRequest, Database.StatusPsa>();
        CreateMap<Model.Requests.LookupUpsertRequest, Database.StatusDonacije>();
        CreateMap<Model.Requests.LookupUpsertRequest, Database.StatusPosjete>();
        CreateMap<Model.Requests.LookupUpsertRequest, Database.StatusZahtjeva>();
        CreateMap<Model.Requests.LookupUpsertRequest, Database.TipDonacije>();
        CreateMap<Model.Requests.LookupUpsertRequest, Database.TipAktivnosti>();
    }
}
