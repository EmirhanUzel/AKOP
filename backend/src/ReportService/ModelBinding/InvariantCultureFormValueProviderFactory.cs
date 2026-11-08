using System.Globalization;

using Microsoft.AspNetCore.Mvc.ModelBinding;

namespace ReportService.ModelBinding;

// Form alanları varsayılan olarak sunucunun kültürüyle okunur. Türkçe makinede
// "39.92" yanlış çevrilebilir; mobil her zaman noktalı gönderdiği için
// form değerleri kültürden bağımsız (InvariantCulture) okunur.
public class InvariantCultureFormValueProviderFactory : IValueProviderFactory
{
    public Task CreateValueProviderAsync(ValueProviderFactoryContext context)
    {
        var request = context.ActionContext.HttpContext.Request;

        if (!request.HasFormContentType)
        {
            return Task.CompletedTask;
        }

        return AddValueProviderAsync(context);
    }

    private static async Task AddValueProviderAsync(ValueProviderFactoryContext context)
    {
        IFormCollection form;

        try
        {
            form = await context.ActionContext.HttpContext.Request.ReadFormAsync();
        }
        catch (InvalidDataException exception)
        {
            // Bozuk veya sınırı aşan form: 400 dönmesi için
            throw new ValueProviderException(exception.Message, exception);
        }
        catch (IOException exception)
        {
            throw new ValueProviderException(exception.Message, exception);
        }

        context.ValueProviders.Add(
            new FormValueProvider(BindingSource.Form, form, CultureInfo.InvariantCulture)
        );
    }
}
