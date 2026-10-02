<% request.setAttribute("fullPage", true); request.setAttribute("searchLabel", "Search"); %>
<%@ include file="../common/header.jsp" %>

<div class="bk-results-top"><div class="container"><%@ include file="../common/searchbar.jsp" %></div></div>

<div class="container">
<c:if test="${not empty infoMessage}"><div class="alert alert-warning">${infoMessage}</div></c:if>

<c:if test="${not empty flights}">
<div class="row g-4">
  <div class="col-lg-3">
    <div class="bk-panel"><h5>Search summary</h5><p class="text-muted mb-0">${from} &rarr; ${to} &middot; results include the day before and after your date.</p></div>
    <h5 class="mt-4">Filters</h5>
    <div class="bk-filter bk-panel">
      <h6>Stops</h6>
      <label><span><input type="radio" name="fStops" value="any" checked> Any</span><span id="cAny"></span></label>
      <label><span><input type="radio" name="fStops" value="Direct"> Direct only</span><span id="cDirect"></span></label>
      <h6 class="mt-3">Meals</h6>
      <label><span><input type="radio" name="fMeals" value="any" checked> Any</span></label>
      <label><span><input type="radio" name="fMeals" value="1"> Meals available</span><span id="cMeals"></span></label>
      <label><span><input type="radio" name="fMeals" value="0"> No meals</span></label>
    </div>
  </div>

  <div class="col-lg-9">
    <div class="d-flex justify-content-between align-items-center mb-3">
      <h5 class="mb-0">We found <span id="total">${fn:length(flights)}</span> flight options</h5>
      <select class="bk-sort" id="sortBy"><option value="best">Sort by: Best</option><option value="price">Sort by: Cheapest</option><option value="dep">Sort by: Departure</option><option value="dur">Sort by: Duration</option></select>
    </div>
    <div id="list">
    <c:forEach var="f" items="${flights}">
      <div class="flight-card" data-price="${f.totalPrice}" data-cat="${f.flightCategory}" data-meals="${f.mealsAvailable ? 1 : 0}" data-dep="${f.departureTime}" data-dur="${f.duration}">
        <div class="fc-main">
          <span class="tag-slot"></span><span class="bk-tag green">Flexible ticket upgrade available</span>
          <div class="fc-leg">
            <div><div class="fc-time">${fn:substring(f.departureFormatted,12,17)}</div><div class="fc-sub">${f.departureAirportId} &middot; ${fn:substring(f.departureFormatted,0,6)}</div></div>
            <div class="fc-line"><span class="pill ${f.flightCategory == 'Direct' ? '' : 'conn'}">${f.flightCategory}</span><hr><div class="fc-sub">${f.duration}</div></div>
            <div><div class="fc-time">${fn:substring(f.arrivalFormatted,12,17)}</div><div class="fc-sub">${f.arrivalAirportId} &middot; ${fn:substring(f.arrivalFormatted,0,6)}</div></div>
          </div>
          <div class="fc-sub"><strong>${f.airlineName}</strong> &middot; ${f.aircraftModel} &middot; ${f.availableSeats} seats left &middot;
            <c:choose><c:when test="${f.mealsAvailable}"><span class="meal-yes">🍽 Meals available</span></c:when><c:otherwise><span class="meal-no">🚫 No meals</span></c:otherwise></c:choose></div>
        </div>
        <div class="fc-side">
          <div><div class="fc-sub">Saver</div><div class="fc-sub">🎒 🧳 ✔</div></div>
          <div class="text-end">
            <div class="fc-price">INR<fmt:formatNumber value="${f.totalPrice}" maxFractionDigits="0"/></div>
            <a class="btn-view mt-2" href="${pageContext.request.contextPath}/passenger/flight?flightId=${f.flightId}">View details</a>
          </div>
        </div>
      </div>
    </c:forEach>
    </div>
  </div>
</div>
<script>
(function(){
  var list=document.getElementById('list');
  var cards=[].slice.call(list.children);
  function mins(s){var h=/(\d+)h/.exec(s),m=/(\d+)m/.exec(s);return (h?+h[1]*60:0)+(m?+m[1]:0);}
  var minP=Math.min.apply(null,cards.map(function(c){return +c.dataset.price;}));
  cards.forEach(function(c){ if(+c.dataset.price===minP) c.querySelector('.tag-slot').innerHTML='<span class="bk-tag">Cheapest</span>'; });
  document.getElementById('cAny').textContent=cards.length;
  document.getElementById('cDirect').textContent=cards.filter(function(c){return c.dataset.cat==='Direct';}).length;
  document.getElementById('cMeals').textContent=cards.filter(function(c){return c.dataset.meals==='1';}).length;
  function apply(){
    var st=document.querySelector('input[name=fStops]:checked').value, ml=document.querySelector('input[name=fMeals]:checked').value, n=0;
    var s=document.getElementById('sortBy').value;
    var sorted=cards.slice().sort(function(a,b){
      if(s==='price') return a.dataset.price-b.dataset.price;
      if(s==='dur') return mins(a.dataset.dur)-mins(b.dataset.dur);
      if(s==='dep') return a.dataset.dep<b.dataset.dep?-1:1;
      return (a.dataset.price/ (1+(a.dataset.meals==='1'?.15:0))) - (b.dataset.price/(1+(b.dataset.meals==='1'?.15:0)));
    });
    sorted.forEach(function(c){
      var show=(st==='any'||c.dataset.cat===st)&&(ml==='any'||c.dataset.meals===ml);
      c.style.display=show?'':'none'; if(show)n++; list.appendChild(c);
    });
    document.getElementById('total').textContent=n;
  }
  document.querySelectorAll('.bk-filter input,#sortBy').forEach(function(e){e.addEventListener('change',apply);});
})();
</script>
</c:if>
</div>
<%@ include file="../common/footer.jsp" %>
