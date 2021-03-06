require 'test_helper'
require 'fileutils'

# Sprockets is inserting a newline after the docblock for some reason...
EXPECTED_JS = <<eos
React.createElement("div", null);
eos

EXPECTED_JS_2 = <<eos
(function() {
  var Component;

  Component = React.createClass({displayName: "Component",
    render: function() {
      return React.createElement(ExampleComponent, {videos:this.props.videos} );
    }
  });

}).call(this);
eos

class JSXTransformTest < ActionDispatch::IntegrationTest

  test 'asset pipeline should transform JSX' do
    get '/assets/example.js'
    FileUtils.rm_r CACHE_PATH if CACHE_PATH.exist?
    assert_response :success
    assert_equal EXPECTED_JS, @response.body
  end

  test 'asset pipeline should transform JSX + Coffeescript' do
    get '/assets/example2.js'
    assert_response :success
    # Different coffee-script may generate slightly different outputs,
    # as some version inserts an extra "\n" at the beginning.
    # Because appraisal is used, multiple versions of coffee-script are treated
    # together. Remove all spaces to make test pass.
    assert_equal EXPECTED_JS_2.gsub(/\s/, ''), @response.body.gsub(/\s/, '')
  end

  test 'can use dropped-in version of JSX transformer' do
    hidden_path = File.expand_path("../dummy/vendor/assets/react/JSXTransformer__.js",  __FILE__)
    replacing_path = File.expand_path("../dummy/vendor/assets/react/JSXTransformer.js",  __FILE__)

    FileUtils.mv hidden_path, replacing_path
    get '/assets/example3.js'

    FileUtils.mv replacing_path, hidden_path
    FileUtils.rm_r CACHE_PATH if CACHE_PATH.exist?

    assert_response :success
    assert_equal 'test_confirmation_token_jsx_transformed;', @response.body
  end

  test 'accepts harmony: true option' do
    React::JSX.transform_options = {harmony: true}
    get '/assets/harmony_example.js'
    assert_response :success
    assert_match(/generateGreeting:\s*function\(\)/, @response.body, "object literal methods")
    assert_match(/React.__spread/, @response.body, "spreading props")
    assert_match(/Your greeting is: '" \+ insertedGreeting \+ "'/, @response.body, "string interpolation")
    assert_match(/active=\$__0\.active/, @response.body, "destructuring assignment")
  end

  test 'accepts strip_types: true option' do
    React::JSX.transform_options = {strip_types: true, harmony: true}
    get '/assets/flow_types_example.js'
    assert_response :success
    assert_match(/\(i\s*,\s*name\s*\)\s*\{/, @response.body, "type annotations are removed")
  end
end
