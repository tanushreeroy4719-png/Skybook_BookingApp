<% request.setAttribute("fullPage", true); %>
<%@ include file="../common/header.jsp" %>
<div class="bk-steps"><div class="container"><ol><li class="on"><span class="n">1</span> Choose your room</li><li class="on"><span class="n">2</span> Your details</li><li><span class="n">3</span> Check and pay</li></ol></div></div>
<div class="container"><div class="row g-4">
  <div class="col-lg-7"><div class="card-skybook p-4">
    <h3>${hotel.HotelName}</h3><div class="fc-sub mb-2">${hotel.Address} &middot; ${hotel.Stars}-star &middot; Rating ${hotel.Rating}</div>
    <p>${hotel.Description}</p><p class="mb-0"><strong>Facilities:</strong> ${hotel.Amenities}</p>
  </div></div>
  <div class="col-lg-5"><div class="card-skybook p-4">
    <form method="post" action="${pageContext.request.contextPath}/passenger/stays">
      <input type="hidden" name="hotelId" value="${hotel.HotelID}">
      <label class="form-label">Check-in</label><input class="form-control mb-2" type="date" name="checkIn" value="${checkIn}" required>
      <label class="form-label">Check-out</label><input class="form-control mb-2" type="date" name="checkOut" value="${checkOut}" required>
      <div class="row"><div class="col"><label class="form-label">Guests</label><input class="form-control" type="number" min="1" name="guests" value="${empty guests ? 1 : guests}"></div>
      <div class="col"><label class="form-label">Rooms</label><input class="form-control" type="number" min="1" name="rooms" value="${empty rooms ? 1 : rooms}"></div></div>
      <div class="fc-sub mt-3">INR<fmt:formatNumber value="${hotel.PricePerNight}" maxFractionDigits="0"/> per night + 12% taxes. No hidden fees.</div>
      <button class="bk-go w-100 mt-3" type="submit">Reserve</button>
    </form>
  </div></div>
</div></div>
<%@ include file="../common/footer.jsp" %>
