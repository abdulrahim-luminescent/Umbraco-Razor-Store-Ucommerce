﻿using System.Linq;
using System.Web.Mvc;
using UCommerce.Api;
using UCommerce.EntitiesV2;
using UmbUcommerce.Models;
using Umbraco.Web;
using Umbraco.Web.Models;
using Umbraco.Web.Mvc;

namespace UmbUcommerce.Controllers
{
    public class BillingController : RenderMvcController
    {
        [HttpGet]
        public override ActionResult Index(RenderModel model)
        {
            var addressDetails = new AddressDetailsViewModel();

            var shippingInformation = TransactionLibrary.GetShippingInformation();
            var billingInformation = TransactionLibrary.GetBillingInformation();

            addressDetails.BillingAddress.FirstName = billingInformation.FirstName;
            addressDetails.BillingAddress.LastName = billingInformation.LastName;
            addressDetails.BillingAddress.EmailAddress = billingInformation.EmailAddress;
            addressDetails.BillingAddress.PhoneNumber = billingInformation.PhoneNumber;
            addressDetails.BillingAddress.MobilePhoneNumber = billingInformation.MobilePhoneNumber;
            addressDetails.BillingAddress.Line1 = billingInformation.Line1;
            addressDetails.BillingAddress.Line2 = billingInformation.Line2;
            addressDetails.BillingAddress.PostalCode = billingInformation.PostalCode;
            addressDetails.BillingAddress.City = billingInformation.City;
            addressDetails.BillingAddress.State = billingInformation.State;
            addressDetails.BillingAddress.Attention = billingInformation.Attention;
            addressDetails.BillingAddress.CompanyName = billingInformation.CompanyName;
            addressDetails.BillingAddress.CountryId = billingInformation.Country != null ? billingInformation.Country.CountryId : -1;

            addressDetails.ShippingAddress.FirstName = shippingInformation.FirstName;
            addressDetails.ShippingAddress.LastName = shippingInformation.LastName;
            addressDetails.ShippingAddress.EmailAddress = shippingInformation.EmailAddress;
            addressDetails.ShippingAddress.PhoneNumber = shippingInformation.PhoneNumber;
            addressDetails.ShippingAddress.MobilePhoneNumber = shippingInformation.MobilePhoneNumber;
            addressDetails.ShippingAddress.Line1 = shippingInformation.Line1;
            addressDetails.ShippingAddress.Line2 = shippingInformation.Line2;
            addressDetails.ShippingAddress.PostalCode = shippingInformation.PostalCode;
            addressDetails.ShippingAddress.City = shippingInformation.City;
            addressDetails.ShippingAddress.State = shippingInformation.State;
            addressDetails.ShippingAddress.Attention = shippingInformation.Attention;
            addressDetails.ShippingAddress.CompanyName = shippingInformation.CompanyName;
            addressDetails.ShippingAddress.CountryId = shippingInformation.Country != null ? shippingInformation.Country.CountryId : -1;

            addressDetails.AvailableCountries = Country.All().ToList().Select(x => new SelectListItem() { Text = x.Name, Value = x.CountryId.ToString() }).ToList();

            return base.View("/Views/BillingShippingAddress.cshtml", addressDetails);
        }

        [HttpPost]
        public ActionResult Index(AddressDetailsViewModel addressDetails)
        {
            var billingDetails = addressDetails.BillingAddress;
            if (!string.IsNullOrEmpty(billingDetails.FirstName) || !string.IsNullOrEmpty(billingDetails.LastName) || 
                !string.IsNullOrEmpty(billingDetails.EmailAddress) || !string.IsNullOrEmpty(billingDetails.MobilePhoneNumber) || !string.IsNullOrEmpty(billingDetails.Line1))
            {
                if (addressDetails.IsShippingAddressDifferent)
                {
                    EditBillingInformation(billingDetails);
                    EditShippingInformation(addressDetails.ShippingAddress);
                }

                else
                {
                    EditBillingInformation(billingDetails);
                    EditShippingInformation(billingDetails);
                }

                TransactionLibrary.ExecuteBasketPipeline();

                var root = UmbracoContext.PublishedContentRequest.PublishedContent.AncestorsOrSelf("homePage").FirstOrDefault();
                var shipping = root.Descendants("shipping").FirstOrDefault();
                return Redirect(shipping.Url);
            }

            return base.View("/Views/BillingShippingAddress.cshtml", addressDetails);
        }

        private void EditShippingInformation(AddressViewModel shippingAddress)
        {
            TransactionLibrary.EditShippingInformation(
          shippingAddress.FirstName,
          shippingAddress.LastName,
          shippingAddress.EmailAddress,
          shippingAddress.PhoneNumber,
          shippingAddress.MobilePhoneNumber,
          shippingAddress.CompanyName,
          shippingAddress.Line1,
          shippingAddress.Line2,
          shippingAddress.PostalCode,
          shippingAddress.City,
          shippingAddress.State,
          shippingAddress.Attention,
          shippingAddress.CountryId);
        }

        private void EditBillingInformation(AddressViewModel billingAddress)
        {
            TransactionLibrary.EditBillingInformation(
               billingAddress.FirstName,
               billingAddress.LastName,
               billingAddress.EmailAddress,
               billingAddress.PhoneNumber,
               billingAddress.MobilePhoneNumber,
               billingAddress.CompanyName,
               billingAddress.Line1,
               billingAddress.Line2,
               billingAddress.PostalCode,
               billingAddress.City,
               billingAddress.State,
               billingAddress.Attention,
               billingAddress.CountryId);
        }
    }
}