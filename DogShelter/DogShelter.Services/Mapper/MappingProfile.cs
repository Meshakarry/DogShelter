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
        CreateMap<Database.Pas, Model.Pas>();
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
        CreateMap<Database.Udomljavanje, Model.Udomljavanje>();
        CreateMap<Database.Uloga, Model.Uloga>();
        CreateMap<Database.VelicinaPsa, Model.VelicinaPsa>();
        CreateMap<Database.Volonter, Model.Volonter>();
        CreateMap<Database.ZahtjevZaUdomljavanje, Model.ZahtjevZaUdomljavanje>();
    }
}
