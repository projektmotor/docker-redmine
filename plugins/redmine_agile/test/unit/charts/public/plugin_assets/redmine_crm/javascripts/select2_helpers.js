var SELECT2_DELAY = 250;

var select2Filters = {};

function setSelect2Filter(type, options) {
  if (typeof operatorByType === 'undefined') { return }

  operatorByType[type] = operatorByType[type] || operatorByType['list_optional'];
  select2Filters[type] = options;
};


var originBuildFilterRow = buildFilterRow;
buildFilterRow = function (field, operator, values) {
  originBuildFilterRow(field, operator, values);

  var options = select2Options(field);
  if (options) {
    setSelect2FilterValues(field, options, values);
    transformToSelect2(field, options);
  }
};


function select2Options(field) {
  var filter = availableFilters[field];
  var options = select2Filters[filter['type']];

  if (!options && filter['field_format']) {
    options = select2Filters[field]
  }

  return options;
};


function setSelect2FilterValues(field, options, values) {
  var needAddValues = !rowHasSelectTag(field);
  if (needAddValues) { addSelectTag(field) }

  var $select = findSelectTagInRowBy(field);
  if (options['multiple'] !== false) { $select.attr('multiple', true) }

  if (needAddValues) { addOptionTags($select, field, values); }
};


function addSelectTag(field) {
  var fieldId = sanitizeToId(field);
  $('#tr_' + fieldId).find('td.values').append(
    '<span style="display:none;"><select class="value" id="values_'+fieldId+'_1" name="v['+field+'][]"></select></span>'
  );
};


function addOptionTags($select, field, values) {
  var filterValues = availableFilters[field]['values'];

  for (var i = 0; i < filterValues.length; i++) {
    var filterValue = filterValues[i];
    var option = $('<option>');

    if ($.isArray(filterValue)) {
      option.val(filterValue[1]).text(filterValue[0]);
      if ($.inArray(filterValue[1], values) > -1) { option.attr('selected', true); }
    } else {
      option.val(filterValue).text(filterValue);
      if ($.inArray(filterValue, values) > -1) { option.attr('selected', true); }
    }

    $select.append(option);
  }
};


function sanitizeToId(field) { return field.replace('.', '_') };

function findSelectTagInRowBy(field) {
  return findInRowBy(field, '.values select.value');
};

function rowHasSelectTag(field) {
  return findInRowBy(field, '.values select.value').length > 0;
};

function rowHasSelect2(field) {
  return findInRowBy(field, '.values .select2').length > 0;
};

function findInRowBy(field, selector) {
  return $('#tr_' + sanitizeToId(field) + ' ' + selector);
};

function formatStateWithAvatar(opt) {
  return $('<span>' + opt.avatar + '&nbsp;' + opt.text + '</span>');
};

function formatStateWithMultiaddress(opt) {
  return $('<span class="select2-contact">' + opt.avatar + '<p class="select2-contact__name">' + opt.text + '</p><p class="select2-contact__email">' + opt.email + '</p></span>');
}

function formatSelectionWithEmails(opt) {
  email = $.trim(opt.email).length ? ' <' + opt.email + '>' : ''
  return (opt.text || opt.name || '') + email
}

function transformToSelect2(field, options) {
  if (rowHasSelect2(field)) { return }

  findInRowBy(field, '.toggle-multiselect').hide();
  var selectField = findSelectTagInRowBy(field);
  selectField.select2(buildSelect2Options(options));

  var select2Instance = selectField.data('select2');
  select2Instance.on('results:message', function(params){
    this.dropdown._resizeDropdown();
    this.dropdown._positionDropdown();
  });
};


function select2Tag(id, options) {
  $(function () {
    var selectField = $('select#' + id);
    selectField.select2(buildSelect2Options(options));

    var select2Instance = selectField.data('select2');
    select2Instance.on('results:message', function(params){
      this.dropdown._resizeDropdown();
      this.dropdown._positionDropdown();
    });
  });
};


function buildSelect2Options(options) {
  result = {
    placeholder: options['placeholder'] || '',
    allowClear: !!options['allow_clear'],
    containerCssClass: options['containerCssClass'],
    minimumInputLength: options['min_input_length'] || 0,
    templateResult: window[options['format_state']],
    templateSelection: window[options['format_selection']],
    width: options['width'] || '60%'
  };

  addDataSourceOptions(result, options);
  addTagsOptions(result, options);

  return result;
};


function addDataSourceOptions(target, options) {
  if (options['url']) {
    target['ajax'] = {
      url: options['url'],
      dataType: 'json',
      delay: SELECT2_DELAY,
      data: function (params) {
        return { q: params.term };
      },
      processResults: function (data, params) {
        return { results: data };
      },
      cache: true
    };
  } else {
    target['data'] = options['data'] || [];
  }
};


function addTagsOptions(target, options) {
  if (options['tags']) {
    target['tags'] = true;
    target['tokenSeparators'] = [','];
    target['createTag'] = createTag;
  } else {
    target['tags'] = false;
  }
};


function createTag(params) {
  var term = $.trim(params.term);
  if (term === '' || term.indexOf(',') > -1) {
    return null; // Return null to disable tag creation
  }

  return { id: term, text: term };
};
