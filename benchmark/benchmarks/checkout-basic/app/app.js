/*
 * checkout-basic — benchmark application logic.
 *
 * All behavior lives in this one file so a mutation is a single-line patch
 * (see ../mutations/). Deliberately plain: no build step, no framework, no
 * network. State is sessionStorage (auth) and localStorage (cart).
 *
 * The instrumentation here is INTENTIONALLY UNEVEN — see ../README.md. A
 * uniformly well-instrumented app would measure the pipeline on easy mode.
 */

'use strict';

var CATALOG = [
  { slug: 'labs-backpack', name: 'Labs Backpack', price: 29.99 },
  { slug: 'bike-light', name: 'Bike Light', price: 9.99 },
  { slug: 'bolt-tshirt', name: 'Bolt T-Shirt', price: 15.99 },
  { slug: 'fleece-jacket', name: 'Fleece Jacket', price: 49.99 }
];

var TAX_RATE = 0.08;

// Local-only demo credentials for a disposable benchmark app. Not a secret,
// not reused anywhere, and the app has no backend to authenticate against.
var VALID_USER = 'demo_user';
var VALID_PASS = 'demo_pass';

var AUTH_KEY = 'bench.auth';
var CART_KEY = 'bench.cart';
var ORDER_SEQ_KEY = 'bench.orderSeq';

/* ---------- state ---------- */

function isAuthed() {
  return sessionStorage.getItem(AUTH_KEY) === '1';
}

function readCart() {
  try {
    return JSON.parse(localStorage.getItem(CART_KEY)) || {};
  } catch (e) {
    return {};
  }
}

function writeCart(cart) {
  localStorage.setItem(CART_KEY, JSON.stringify(cart));
}

function productBySlug(slug) {
  for (var i = 0; i < CATALOG.length; i++) {
    if (CATALOG[i].slug === slug) return CATALOG[i];
  }
  return null;
}

function money(value) {
  return '$' + value.toFixed(2);
}

/* ---------- totals ---------- */

function cartSubtotal() {
  var cart = readCart();
  var sum = 0;
  Object.keys(cart).forEach(function (slug) {
    var product = productBySlug(slug);
    if (product) sum += product.price * cart[slug];
  });
  return Math.round(sum * 100) / 100;
}

function cartTax() {
  return Math.round(cartSubtotal() * TAX_RATE * 100) / 100;
}

function cartTotal() {
  return Math.round((cartSubtotal() + cartTax()) * 100) / 100;
}

/* ---------- route guard ---------- */

function requireAuth() {
  if (!isAuthed()) {
    window.location.replace('index.html?denied=1');
    return false;
  }
  return true;
}

/* ---------- login ---------- */

function initLogin() {
  var form = document.getElementById('login-form');
  var error = document.querySelector('[data-test="error"]');

  if (new URLSearchParams(window.location.search).has('denied')) {
    error.textContent = 'Please sign in to continue.';
    error.hidden = false;
  }

  form.addEventListener('submit', function (event) {
    event.preventDefault();
    var user = document.querySelector('[data-test="username"]').value.trim();
    var pass = document.querySelector('[data-test="password"]').value;

    if (user === '' || pass === '') {
      error.textContent = 'Username and password are required.';
      error.hidden = false;
      return;
    }

    if (user !== VALID_USER || pass !== VALID_PASS) {
      error.textContent = 'Username and password do not match any account.';
      error.hidden = false;
      return;
    }

    sessionStorage.setItem(AUTH_KEY, '1');
    window.location.href = 'products.html';
  });
}

/* ---------- products ---------- */

function initProducts() {
  if (!requireAuth()) return;
  var list = document.getElementById('product-list');

  CATALOG.forEach(function (product) {
    var card = document.createElement('div');
    card.className = 'product';
    // Shared value across every card, exactly like real component libraries.
    card.setAttribute('data-test', 'product-card');

    var name = document.createElement('h3');
    name.setAttribute('data-test', 'product-name');
    name.textContent = product.name;

    var price = document.createElement('span');
    price.setAttribute('data-test', 'product-price');
    price.textContent = money(product.price);

    var add = document.createElement('button');
    add.setAttribute('data-test', 'add-to-cart-' + product.slug);
    add.textContent = 'Add to cart';
    add.addEventListener('click', function () {
      var cart = readCart();
      cart[product.slug] = (cart[product.slug] || 0) + 1;
      writeCart(cart);
      renderCartBadge();
    });

    card.appendChild(name);
    card.appendChild(price);
    card.appendChild(add);
    list.appendChild(card);
  });

  renderCartBadge();
}

function renderCartBadge() {
  var badge = document.querySelector('[data-test="cart-badge"]');
  if (!badge) return;
  var cart = readCart();
  var count = Object.keys(cart).reduce(function (sum, slug) {
    return sum + cart[slug];
  }, 0);
  // Absent from the DOM entirely when empty, not merely hidden.
  badge.textContent = count > 0 ? String(count) : '';
  badge.hidden = count === 0;
}

/* ---------- cart ---------- */

function initCart() {
  if (!requireAuth()) return;
  renderCart();
}

function renderCart() {
  var rows = document.getElementById('cart-rows');
  var cart = readCart();
  rows.innerHTML = '';

  Object.keys(cart).forEach(function (slug) {
    var product = productBySlug(slug);
    if (!product) return;

    var row = document.createElement('div');
    row.className = 'cart-row';

    var name = document.createElement('span');
    name.className = 'cart-name';
    name.textContent = product.name;

    // Quantity input has no test-id but a real associated <label>, so it is
    // addressable via getByLabel — a "fallback available" gap.
    var label = document.createElement('label');
    label.setAttribute('for', 'qty-' + slug);
    label.textContent = 'Quantity for ' + product.name;

    var qty = document.createElement('input');
    qty.type = 'number';
    qty.min = '1';
    qty.id = 'qty-' + slug;
    qty.value = String(cart[slug]);
    qty.addEventListener('change', function () {
      var next = parseInt(qty.value, 10);
      if (isNaN(next) || next < 1) next = 1;
      var current = readCart();
      current[slug] = next;
      writeCart(current);
      renderCart();
    });

    // Remove control: no test-id, no role, no accessible name, and identical
    // text on every row. This is a genuine "no fallback" gap and should
    // produce a test.fixme(), never an invented selector.
    var remove = document.createElement('span');
    remove.className = 'row-x';
    remove.setAttribute('data-idx', slug);
    remove.textContent = '×';
    remove.addEventListener('click', function () {
      var current = readCart();
      delete current[slug];
      writeCart(current);
      renderCart();
    });

    row.appendChild(name);
    row.appendChild(label);
    row.appendChild(qty);
    row.appendChild(remove);
    rows.appendChild(row);
  });

  document.querySelector('[data-test="cart-subtotal"]').textContent = money(cartSubtotal());
  renderCartBadge();
}

/* ---------- checkout ---------- */

function initCheckout() {
  if (!requireAuth()) return;
  renderSummary();

  document.getElementById('checkout-form').addEventListener('submit', function (event) {
    event.preventDefault();
    var error = document.querySelector('[data-test="checkout-error"]');
    var name = document.querySelector('input[aria-label="Full name"]').value.trim();
    var card = document.querySelector('input[aria-label="Card number"]').value.trim();

    // Deliberate behavioral quirk: a blank name produces NO feedback at all.
    // Nothing is technically missing from the DOM, so this is a Section 3
    // behavioral finding rather than a selector gap.
    if (name === '') {
      return;
    }

    if (!/^[0-9]{16}$/.test(card)) {
      error.textContent = 'Card number must be 16 digits.';
      error.hidden = false;
      return;
    }

    var seq = parseInt(localStorage.getItem(ORDER_SEQ_KEY) || '1000', 10) + 1;
    localStorage.setItem(ORDER_SEQ_KEY, String(seq));
    sessionStorage.setItem('bench.lastOrder', 'ORD-' + seq);
    localStorage.removeItem(CART_KEY);
    window.location.href = 'confirm.html';
  });
}

function renderSummary() {
  document.querySelector('[data-test="summary-subtotal"]').textContent = money(cartSubtotal());
  document.querySelector('[data-test="summary-tax"]').textContent = money(cartTax());
  document.querySelector('[data-test="summary-total"]').textContent = money(cartTotal());
}

/* ---------- confirmation ---------- */

function initConfirm() {
  if (!requireAuth()) return;
  var orderId = sessionStorage.getItem('bench.lastOrder') || '';
  document.querySelector('[data-test="order-id"]').textContent = orderId;
  renderCartBadge();
}
